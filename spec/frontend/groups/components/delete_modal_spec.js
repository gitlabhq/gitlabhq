import { GlModal, GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeleteModal from '~/groups/components/delete_modal.vue';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { stubComponent } from 'helpers/stub_component';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

jest.mock('lodash/uniqueId', () => () => 'fake-id');

describe('DeleteModal', () => {
  let wrapper;

  const defaultPropsData = {
    visible: false,
    confirmPhrase: 'foo',
    subgroupsCount: 1000,
    projectsCount: 1000000,
    confirmLoading: false,
    fullName: 'Foo / Bar',
    markedForDeletion: false,
    permanentDeletionDate: '2025-11-28',
  };

  const createComponent = (propsData) => {
    wrapper = mountExtended(DeleteModal, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  const findGroupsProjectsDeleteModal = () => wrapper.findComponent(GroupsProjectsDeleteModal);
  const alertText = () => wrapper.findComponent(GlAlert).text();

  it('renders GroupsProjectsDeleteModal with correct props', () => {
    createComponent();

    expect(findGroupsProjectsDeleteModal().props()).toMatchObject({
      visible: defaultPropsData.visible,
      resourceType: RESOURCE_TYPES.GROUP,
      confirmPhrase: defaultPropsData.confirmPhrase,
      confirmLoading: defaultPropsData.confirmLoading,
      fullName: defaultPropsData.fullName,
      markedForDeletion: defaultPropsData.markedForDeletion,
      permanentDeletionDate: defaultPropsData.permanentDeletionDate,
    });
  });

  describe('when resource counts are set', () => {
    it('displays resource counts', () => {
      createComponent();

      expect(alertText()).toContain('1k subgroups');
      expect(alertText()).toContain('1m projects');
    });
  });

  describe('when resource counts are not set', () => {
    it('does not display resource counts', () => {
      createComponent({
        subgroupsCount: null,
        projectsCount: null,
      });

      expect(wrapper.findByTestId('group-delete-modal-stats').exists()).toBe(false);
    });
  });

  it('emits `primary` event', () => {
    createComponent();

    findGroupsProjectsDeleteModal().vm.$emit('primary');

    expect(wrapper.emitted('primary')).toEqual([[]]);
  });

  it('emits `change` event', () => {
    createComponent();

    findGroupsProjectsDeleteModal().vm.$emit('change', true);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  describe('when markedForDeletion prop is false', () => {
    it('renders restore message help page link', () => {
      createComponent();

      const helpPageLinkComponent = wrapper.findComponent(HelpPageLink);

      expect(helpPageLinkComponent.props()).toEqual({
        href: 'user/group/_index',
        anchor: 'restore-a-group',
      });
      expect(helpPageLinkComponent.text()).toBe('Learn more');
    });
  });

  describe('when markedForDeletion prop is true', () => {
    it('does not render restore message help page link', () => {
      createComponent({ markedForDeletion: true });

      expect(wrapper.findComponent(HelpPageLink).exists()).toBe(false);
    });
  });
});
