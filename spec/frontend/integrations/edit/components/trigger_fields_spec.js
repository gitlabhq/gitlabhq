import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { placeholderForType } from 'jh_else_ce/integrations/constants';
import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';

Vue.use(Vuex);

describe('TriggerFields', () => {
  let wrapper;
  let store;

  const defaultProps = {
    type: 'slack',
  };

  const createComponent = (props, isInheriting = false) => {
    store = new Vuex.Store({
      getters: {
        isInheriting: () => isInheriting,
      },
    });

    wrapper = mountExtended(TriggerFields, {
      propsData: { ...defaultProps, ...props },
      store,
    });
  };

  const findTriggerLabel = () => wrapper.findByTestId('trigger-fields-group').find('label');
  const findAllGlFormGroups = () => wrapper.find('#trigger-fields').findAllComponents(GlFormGroup);
  const findAllGlFormCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findAllGlFormInputs = () => wrapper.findAllComponents(GlFormInput);

  describe('placeholder text on the event fields and default values', () => {
    const dummyFieldPlaceholder = '#foo';
    const integrationTypes = {
      INTEGRATION_TYPE_SLACK: 'slack',
      INTEGRATION_TYPE_SLACK_APPLICATION: 'gitlab_slack_application',
      INTEGRATION_TYPE_MATTERMOST: 'mattermost',
      INTEGRATION_TYPE_NON_EXISTING: 'non_existing',
    };
    it.each`
      integrationType                                        | fieldPlaceholder         | expectedPlaceholder
      ${integrationTypes.INTEGRATION_TYPE_SLACK}             | ${undefined}             | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_SLACK]}
      ${integrationTypes.INTEGRATION_TYPE_SLACK}             | ${''}                    | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_SLACK]}
      ${integrationTypes.INTEGRATION_TYPE_SLACK}             | ${dummyFieldPlaceholder} | ${dummyFieldPlaceholder}
      ${integrationTypes.INTEGRATION_TYPE_SLACK_APPLICATION} | ${undefined}             | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_SLACK_APPLICATION]}
      ${integrationTypes.INTEGRATION_TYPE_SLACK_APPLICATION} | ${''}                    | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_SLACK_APPLICATION]}
      ${integrationTypes.INTEGRATION_TYPE_SLACK_APPLICATION} | ${dummyFieldPlaceholder} | ${dummyFieldPlaceholder}
      ${integrationTypes.INTEGRATION_TYPE_MATTERMOST}        | ${undefined}             | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_MATTERMOST]}
      ${integrationTypes.INTEGRATION_TYPE_MATTERMOST}        | ${''}                    | ${placeholderForType[integrationTypes.INTEGRATION_TYPE_MATTERMOST]}
      ${integrationTypes.INTEGRATION_TYPE_MATTERMOST}        | ${dummyFieldPlaceholder} | ${dummyFieldPlaceholder}
      ${integrationTypes.INTEGRATION_TYPE_NON_EXISTING}      | ${undefined}             | ${undefined}
      ${integrationTypes.INTEGRATION_TYPE_NON_EXISTING}      | ${''}                    | ${undefined}
      ${integrationTypes.INTEGRATION_TYPE_NON_EXISTING}      | ${dummyFieldPlaceholder} | ${dummyFieldPlaceholder}
    `(
      'passed down correct placeholder for "$integrationType" type and "$fieldPlaceholder" placeholder on the field',
      ({ integrationType, fieldPlaceholder, expectedPlaceholder }) => {
        createComponent({
          type: integrationType,
          events: [
            {
              field: {
                name: 'foo',
                value: '',
                placeholder: fieldPlaceholder,
              },
            },
          ],
        });
        const field = wrapper.findComponent(GlFormInput);

        expect(field.attributes('placeholder')).toBe(expectedPlaceholder);
      },
    );
  });

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
          title: 'Push',
          name: 'push_event',
          description: 'Event on push',
          value: true,
        },
        {
          title: 'Merge request',
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
          { labelText: 'Merge request', inputName: 'service[merge_requests_event]' },
        ];
        expect(checkboxes).toHaveLength(2);

        checkboxes.wrappers.forEach((checkbox, index) => {
          const checkBox = checkbox.findComponent(GlFormCheckbox);

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
          expect(field.props('readonly')).toBe(isInheriting);
          expect(field.props('value')).toBe(events[index].field.value);
        });
      });
    });
  });
});
