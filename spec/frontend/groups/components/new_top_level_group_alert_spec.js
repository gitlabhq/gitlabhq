import { shallowMount } from '@vue/test-utils';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('NewTopLevelGroupAlert', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const findAlert = () => wrapper.findComponent({ ref: 'newTopLevelAlert' });
  const createSubGroupPath = '/groups/new?parent_id=1#create-group-pane';

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMount(NewTopLevelGroupAlert, {
      provide: {
        createSubGroupPath,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when the component is created', () => {
    beforeEach(() => {
      createComponent({
        shouldShowCallout: true,
      });
    });

    it('renders a button with a link to create a new sub-group', () => {
      expect(findAlert().props('primaryButtonText')).toBe(
        NewTopLevelGroupAlert.i18n.primaryBtnText,
      );
      expect(findAlert().props('primaryButtonLink')).toBe(
        helpPagePath('user/group/subgroups/_index'),
      );
    });
  });

  describe('dismissing the alert', () => {
    beforeEach(() => {
      findAlert().vm.$emit('dismiss');
    });

    it('calls the dismiss callback', () => {
      expect(userCalloutDismissSpy).toHaveBeenCalled();
    });
  });

  describe('when the alert has been dismissed', () => {
    beforeEach(() => {
      createComponent({
        shouldShowCallout: false,
      });
    });

    it('does not show the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });
});
