import { mount } from '@vue/test-utils';
import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';

describe('TriggerFields', () => {
  let wrapper;

  const defaultProps = {
    type: 'slack',
  };

  const createComponent = props => {
    wrapper = mount(TriggerFields, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findAllGlFormCheckboxes = () => wrapper.findAll(GlFormCheckbox);
  const findAllGlFormInputs = () => wrapper.findAll(GlFormInput);

  describe('template', () => {
    it('renders a label with text "Trigger"', () => {
      createComponent();

      const triggerLabel = wrapper.find('[data-testid="trigger-fields-group"]').find('label');
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
        createComponent({
          events,
        });
      });

      it('does not render GlFormInput for each event', () => {
        expect(findAllGlFormInputs().exists()).toBe(false);
      });

      it('renders GlFormInput with description for each event', () => {
        const groups = wrapper.find('#trigger-fields').findAll(GlFormGroup);

        expect(groups).toHaveLength(2);
        groups.wrappers.forEach((group, index) => {
          expect(group.find('small').text()).toBe(events[index].description);
        });
      });

      it('renders GlFormCheckbox for each event', () => {
        const checkboxes = findAllGlFormCheckboxes();
        const expectedResults = [
          { labelText: 'Push', inputName: 'service[push_event]' },
          { labelText: 'Merge Request', inputName: 'service[merge_requests_event]' },
        ];
        expect(checkboxes).toHaveLength(2);

        checkboxes.wrappers.forEach((checkbox, index) => {
          expect(checkbox.find('label').text()).toBe(expectedResults[index].labelText);
          expect(checkbox.find('input').attributes('name')).toBe(expectedResults[index].inputName);
          expect(checkbox.vm.$attrs.checked).toBe(events[index].value);
        });
      });
    });

    describe('events with field property', () => {
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
        createComponent({
          events,
        });
      });

      it('renders GlFormCheckbox for each event', () => {
        expect(findAllGlFormCheckboxes()).toHaveLength(2);
      });

      it('renders GlFormInput for each event', () => {
        const fields = findAllGlFormInputs();
        const expectedResults = [
          {
            name: 'service[push_channel]',
            placeholder: 'Slack channels (e.g. general, development)',
          },
          {
            name: 'service[merge_request_channel]',
            placeholder: 'Slack channels (e.g. general, development)',
          },
        ];

        expect(fields).toHaveLength(2);

        fields.wrappers.forEach((field, index) => {
          expect(field.attributes()).toMatchObject(expectedResults[index]);
          expect(field.vm.$attrs.value).toBe(events[index].field.value);
        });
      });
    });
  });
});
