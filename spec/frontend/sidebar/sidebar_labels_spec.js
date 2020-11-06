import { shallowMount } from '@vue/test-utils';
import {
  mockLabels,
  mockRegularLabel,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';
import updateIssueLabelsMutation from '~/boards/queries/issue_set_labels.mutation.graphql';
import { MutationOperationMode } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
import SidebarLabels from '~/sidebar/components/labels/sidebar_labels.vue';
import updateMergeRequestLabelsMutation from '~/sidebar/queries/update_merge_request_labels.mutation.graphql';
import { toLabelGid } from '~/sidebar/utils';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

describe('sidebar labels', () => {
  let wrapper;

  const defaultProps = {
    allowLabelCreate: true,
    allowLabelEdit: true,
    allowScopedLabels: true,
    canEdit: true,
    iid: '1',
    initiallySelectedLabels: mockLabels,
    issuableType: 'issue',
    labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json?include_ancestor_groups=true',
    labelsManagePath: '/gitlab-org/gitlab-test/-/labels',
    projectIssuesPath: '/gitlab-org/gitlab-test/-/issues',
    projectPath: 'gitlab-org/gitlab-test',
  };

  const $apollo = {
    mutate: jest.fn().mockResolvedValue(),
  };

  const userUpdatedLabels = [
    {
      ...mockRegularLabel,
      set: false,
    },
    {
      id: 40,
      title: 'Security',
      color: '#ddd',
      text_color: '#fff',
      set: true,
    },
    {
      id: 55,
      title: 'Tooling',
      color: '#ddd',
      text_color: '#fff',
      set: false,
    },
  ];

  const findLabelsSelect = () => wrapper.find(LabelsSelect);

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(SidebarLabels, {
      provide: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $apollo,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('LabelsSelect props', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('are as expected', () => {
      expect(findLabelsSelect().props()).toMatchObject({
        allowLabelCreate: defaultProps.allowLabelCreate,
        allowLabelEdit: defaultProps.allowLabelEdit,
        allowMultiselect: true,
        allowScopedLabels: defaultProps.allowScopedLabels,
        footerCreateLabelTitle: 'Create project label',
        footerManageLabelTitle: 'Manage project labels',
        labelsCreateTitle: 'Create project label',
        labelsFetchPath: defaultProps.labelsFetchPath,
        labelsFilterBasePath: defaultProps.projectIssuesPath,
        labelsManagePath: defaultProps.labelsManagePath,
        labelsSelectInProgress: false,
        selectedLabels: defaultProps.initiallySelectedLabels,
        variant: DropdownVariant.Sidebar,
      });
    });
  });

  describe('when type is issue', () => {
    beforeEach(() => {
      mountComponent({ issuableType: IssuableType.Issue });
    });

    describe('when labels are updated', () => {
      it('invokes a mutation', () => {
        findLabelsSelect().vm.$emit('updateSelectedLabels', userUpdatedLabels);

        const expected = {
          mutation: updateIssueLabelsMutation,
          variables: {
            input: {
              addLabelIds: [40],
              iid: defaultProps.iid,
              projectPath: defaultProps.projectPath,
              removeLabelIds: [26, 55],
            },
          },
        };

        expect($apollo.mutate).toHaveBeenCalledWith(expected);
      });
    });

    describe('when label `x` is clicked', () => {
      it('invokes a mutation', () => {
        findLabelsSelect().vm.$emit('onLabelRemove', 27);

        const expected = {
          mutation: updateIssueLabelsMutation,
          variables: {
            input: {
              iid: defaultProps.iid,
              projectPath: defaultProps.projectPath,
              removeLabelIds: [27],
            },
          },
        };

        expect($apollo.mutate).toHaveBeenCalledWith(expected);
      });
    });
  });

  describe('when type is merge_request', () => {
    beforeEach(() => {
      mountComponent({ issuableType: IssuableType.MergeRequest });
    });

    describe('when labels are updated', () => {
      it('invokes a mutation', () => {
        findLabelsSelect().vm.$emit('updateSelectedLabels', userUpdatedLabels);

        const expected = {
          mutation: updateMergeRequestLabelsMutation,
          variables: {
            input: {
              iid: defaultProps.iid,
              labelIds: [toLabelGid(27), toLabelGid(28), toLabelGid(29), toLabelGid(40)],
              operationMode: MutationOperationMode.Replace,
              projectPath: defaultProps.projectPath,
            },
          },
        };

        expect($apollo.mutate).toHaveBeenCalledWith(expected);
      });
    });

    describe('when label `x` is clicked', () => {
      it('invokes a mutation', () => {
        findLabelsSelect().vm.$emit('onLabelRemove', 27);

        const expected = {
          mutation: updateMergeRequestLabelsMutation,
          variables: {
            input: {
              iid: defaultProps.iid,
              labelIds: [toLabelGid(27)],
              operationMode: MutationOperationMode.Remove,
              projectPath: defaultProps.projectPath,
            },
          },
        };

        expect($apollo.mutate).toHaveBeenCalledWith(expected);
      });
    });
  });
});
