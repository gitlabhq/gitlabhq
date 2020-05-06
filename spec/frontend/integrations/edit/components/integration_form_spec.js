import { shallowMount } from '@vue/test-utils';
import IntegrationForm from '~/integrations/edit/components/integration_form.vue';
import ActiveToggle from '~/integrations/edit/components/active_toggle.vue';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';

describe('IntegrationForm', () => {
  let wrapper;

  const defaultProps = {
    activeToggleProps: {
      initialActivated: true,
    },
    showActive: true,
    triggerFieldsProps: {
      initialTriggerCommit: false,
      initialTriggerMergeRequest: false,
      initialEnableComments: false,
    },
    type: '',
  };

  const createComponent = props => {
    wrapper = shallowMount(IntegrationForm, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        ActiveToggle,
        JiraTriggerFields,
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findActiveToggle = () => wrapper.find(ActiveToggle);
  const findJiraTriggerFields = () => wrapper.find(JiraTriggerFields);

  describe('template', () => {
    describe('showActive is true', () => {
      it('renders ActiveToggle', () => {
        createComponent();

        expect(findActiveToggle().exists()).toBe(true);
      });
    });

    describe('showActive is false', () => {
      it('does not render ActiveToggle', () => {
        createComponent({
          showActive: false,
        });

        expect(findActiveToggle().exists()).toBe(false);
      });
    });

    describe('type is "slack"', () => {
      it('does not render JiraTriggerFields', () => {
        createComponent({
          type: 'slack',
        });

        expect(findJiraTriggerFields().exists()).toBe(false);
      });
    });

    describe('type is "jira"', () => {
      it('renders JiraTriggerFields', () => {
        createComponent({
          type: 'jira',
        });

        expect(findJiraTriggerFields().exists()).toBe(true);
      });
    });
  });
});
