import { shallowMount } from '@vue/test-utils';
import SidebarLabels from '~/sidebar/components/labels/sidebar_labels.vue';
import {
  DropdownVariant,
  LabelType,
} from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';

describe('sidebar labels', () => {
  let wrapper;

  const defaultProps = {
    allowLabelEdit: true,
    iid: '1',
    issuableType: 'issue',
    projectIssuesPath: '/gitlab-org/gitlab-test/-/issues',
    fullPath: 'gitlab-org/gitlab-test',
  };

  const findLabelsSelect = () => wrapper.find(LabelsSelect);

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(SidebarLabels, {
      provide: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('LabelsSelect props', () => {
    describe.each`
      issuableType
      ${'issue'}
      ${'merge_request'}
    `('issuableType $issuableType', ({ issuableType }) => {
      beforeEach(() => {
        mountComponent({ issuableType });
      });

      it('has expected props', () => {
        expect(findLabelsSelect().props()).toMatchObject({
          iid: defaultProps.iid,
          fullPath: defaultProps.fullPath,
          allowLabelRemove: defaultProps.allowLabelEdit,
          allowMultiselect: true,
          footerCreateLabelTitle: 'Create project label',
          footerManageLabelTitle: 'Manage project labels',
          labelsCreateTitle: 'Create project label',
          labelsFilterBasePath: defaultProps.projectIssuesPath,
          variant: DropdownVariant.Sidebar,
          issuableType,
          workspaceType: 'project',
          attrWorkspacePath: defaultProps.fullPath,
          labelCreateType: LabelType.project,
        });
      });
    });
  });
});
