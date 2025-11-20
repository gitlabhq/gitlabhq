import { GlModal, GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import { sprintf } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { stubComponent } from 'helpers/stub_component';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

jest.mock('lodash/uniqueId', () => () => 'fake-id');

describe('DeleteModal', () => {
  let wrapper;

  const defaultPropsData = {
    visible: false,
    confirmPhrase: 'foo',
    isFork: false,
    issuesCount: 1000,
    mergeRequestsCount: 1,
    forksCount: 1000000,
    starsCount: 100,
    confirmLoading: false,
    nameWithNamespace: 'Foo / Bar',
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
      resourceType: RESOURCE_TYPES.PROJECT,
      confirmPhrase: defaultPropsData.confirmPhrase,
      confirmLoading: defaultPropsData.confirmLoading,
      fullName: defaultPropsData.nameWithNamespace,
      markedForDeletion: defaultPropsData.markedForDeletion,
      permanentDeletionDate: defaultPropsData.permanentDeletionDate,
    });
  });

  describe('when resource counts are set', () => {
    it('displays resource counts', () => {
      createComponent();

      expect(alertText()).toContain('1k issues');
      expect(alertText()).toContain('1 merge request');
      expect(alertText()).toContain('1m forks');
      expect(alertText()).toContain('100 stars');
    });
  });

  describe('when resource counts are not set', () => {
    it('does not display resource counts', () => {
      createComponent({
        issuesCount: null,
        mergeRequestsCount: null,
        forksCount: null,
        starsCount: null,
      });

      expect(wrapper.findByTestId('project-delete-modal-stats').exists()).toBe(false);
    });
  });

  describe('when project is a fork', () => {
    beforeEach(() => {
      createComponent({
        isFork: true,
      });
    });

    it('displays correct alert title', () => {
      expect(alertText()).toContain(DeleteModal.i18n.isForkAlertTitle);
    });

    it('displays correct alert body', () => {
      expect(alertText()).toContain(DeleteModal.i18n.isForkAlertBody);
    });
  });

  describe('when project is not a fork', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays correct alert title', () => {
      expect(alertText()).toContain(
        sprintf(DeleteModal.i18n.isNotForkAlertTitle, { strongStart: '', strongEnd: '' }),
      );
    });

    it('displays correct alert body', () => {
      expect(alertText()).toContain(
        sprintf(DeleteModal.i18n.isNotForkAlertBody, { strongStart: '', strongEnd: '' }),
      );
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
        href: 'user/project/working_with_projects',
        anchor: 'restore-a-project',
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
