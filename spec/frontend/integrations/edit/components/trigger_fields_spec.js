import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';

describe('TriggerFields', () => {
  let wrapper;

  const defaultProps = {
    type: 'slack',
  };

  const createComponent = (props, isInheriting = false) => {
    wrapper = mountExtended(TriggerFields, {
      propsData: { ...defaultProps, ...props },
      computed: {
        isInheriting: () => isInheriting,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findTriggerLabel = () => wrapper.findByTestId('trigger-fields-group').find('label');
  const findAllGlFormGroups = () => wrapper.find('#trigger-fields').findAll(GlFormGroup);
  const findAllGlFormCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findAllGlFormInputs = () => wrapper.findAllComponents(GlFormInput);

  describe.each([true, false])('template, isInheriting = `%p`', (isInheriting) => {
    it('renders a label with text "Trigger"', () => {
      createComponent();

      const triggerLabel = findTriggerLabel();
      expect(triggerLabel.exists()).toBe(true);
      expect(triggerLabel.text()).toBe('Trigger');
    });

    describe('events without field property', () => {
      const events = [
        {
          title: 'push',
          name: 'push_event',
          description: 'Event on push',
          value: true,
        },
        {
          title: 'merge_request',
          name: 'merge_requests_event',
          description: 'Event on merge_request',
          value: false,
        },
      ];

      beforeEach(() => {
        createComponent(
          {
            events,
          },
          isInheriting,
        );
      });

      it('does not render GlFormInput for each event', () => {
        expect(findAllGlFormInputs().exists()).toBe(false);
      });

      it('renders GlFormInput with description for each event', () => {
        const groups = findAllGlFormGroups();

        expect(groups).toHaveLength(2);
        groups.wrappers.forEach((group, index) => {
          expect(group.find('small').text()).toBe(events[index].description);
        });
      });

      it(`renders GlFormCheckbox and corresponding hidden input for each event, which ${
        isInheriting ? 'is' : 'is not'
      } disabled`, () => {
        const checkboxes = findAllGlFormGroups();
        const expectedResults = [
          { labelText: 'Push', inputName: 'service[push_event]' },
          { labelText: 'Merge Request', inputName: 'service[merge_requests_event]' },
        ];
        expect(checkboxes).toHaveLength(2);

        checkboxes.wrappers.forEach((checkbox, index) => {
          const checkBox = checkbox.find(GlFormCheckbox);

          expect(checkbox.find('label').text()).toBe(expectedResults[index].labelText);
          expect(checkbox.find('[type=hidden]').attributes('name')).toBe(
            expectedResults[index].inputName,
          );
          expect(checkbox.find('[type=hidden]').attributes('value')).toBe(
            events[index].value.toString(),
          );
          expect(checkBox.vm.$attrs.disabled).toBe(isInheriting);
          expect(checkBox.vm.$attrs.checked).toBe(events[index].value);
        });
      });
    });

    describe('events with field property, isInheriting = `%p`', () => {
      const events = [
        {
          field: {
            name: 'push_channel',
            value: '',
          },
        },
        {
          field: {
            name: 'merge_request_channel',
            value: 'gitlab-development',
          },
        },
      ];

      beforeEach(() => {
        createComponent(
          {
            events,
          },
          isInheriting,
        );
      });

      it('renders GlFormCheckbox for each event', () => {
        expect(findAllGlFormCheckboxes()).toHaveLength(2);
      });

      it(`renders GlFormInput for each event, which ${
        isInheriting ? 'is' : 'is not'
      } readonly`, () => {
        const fields = findAllGlFormInputs();
        const expectedResults = [
          {
            name: 'service[push_channel]',
            placeholder: '#general, #development',
          },
          {
            name: 'service[merge_request_channel]',
            placeholder: '#general, #development',
          },
        ];

        expect(fields).toHaveLength(2);

        fields.wrappers.forEach((field, index) => {
          expect(field.attributes()).toMatchObject(expectedResults[index]);
          expect(field.vm.$attrs.readonly).toBe(isInheriting);
          expect(field.vm.$attrs.value).toBe(events[index].field.value);
        });
      });
    });
  });
});
