import { shallowMount } from '@vue/test-utils';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import ConfidentialIssueSidebar from '~/sidebar/components/confidential/confidential_issue_sidebar.vue';
import EditForm from '~/sidebar/components/confidential/edit_form.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import createStore from '~/notes/stores';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

jest.mock('~/flash');
jest.mock('~/sidebar/services/sidebar_service');

describe('Confidential Issue Sidebar Block', () => {
  useMockLocationHelper();

  let wrapper;
  const mutate = jest
    .fn()
    .mockResolvedValue({ data: { issueSetConfidential: { issue: { confidential: true } } } });

  const createComponent = ({ propsData, data = {} }) => {
    const store = createStore();
    const service = new SidebarService();
    wrapper = shallowMount(ConfidentialIssueSidebar, {
      store,
      data() {
        return data;
      },
      propsData: {
        service,
        iid: '',
        fullPath: '',
        ...propsData,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    confidential | isEditable
    ${false}     | ${false}
    ${false}     | ${true}
    ${true}      | ${false}
    ${true}      | ${true}
  `(
    'renders for confidential = $confidential and isEditable = $isEditable',
    ({ confidential, isEditable }) => {
      createComponent({
        propsData: {
          isEditable,
        },
      });
      wrapper.vm.$store.state.noteableData.confidential = confidential;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    },
  );

  describe('if editable', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isEditable: true,
        },
      });
      wrapper.vm.$store.state.noteableData.confidential = true;
    });

    it('displays the edit form when editable', () => {
      wrapper.setData({ edit: false });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find({ ref: 'editLink' }).trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(wrapper.find(EditForm).exists()).toBe(true);
        });
    });

    it('displays the edit form when opened from collapsed state', () => {
      wrapper.setData({ edit: false });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find({ ref: 'collapseIcon' }).trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(wrapper.find(EditForm).exists()).toBe(true);
        });
    });

    it('tracks the event when "Edit" is clicked', () => {
      const spy = mockTracking('_category_', wrapper.element, jest.spyOn);

      const editLink = wrapper.find({ ref: 'editLink' });
      triggerEvent(editLink.element);

      expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
        label: 'right_sidebar',
        property: 'confidentiality',
      });
    });
  });
});
