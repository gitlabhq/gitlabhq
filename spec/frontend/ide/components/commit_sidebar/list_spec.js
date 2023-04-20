import { shallowMount } from '@vue/test-utils';
import CommitSidebarList from '~/ide/components/commit_sidebar/list.vue';
import ListItem from '~/ide/components/commit_sidebar/list_item.vue';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list', () => {
  let wrapper;

  const mountComponent = ({ fileList }) =>
    shallowMount(CommitSidebarList, {
      propsData: {
        title: 'Staged',
        fileList,
        action: 'stageAllChanges',
        actionBtnText: 'stage all',
        actionBtnIcon: 'history',
        activeFileKey: 'staged-testing',
        keyPrefix: 'staged',
      },
    });

  describe('with a list of files', () => {
    beforeEach(() => {
      const f = file('file name');
      f.changed = true;
      wrapper = mountComponent({ fileList: [f] });
    });

    it('renders list', () => {
      expect(wrapper.findAllComponents(ListItem)).toHaveLength(1);
    });
  });

  describe('with empty files array', () => {
    beforeEach(() => {
      wrapper = mountComponent({ fileList: [] });
    });

    it('renders no changes text', () => {
      expect(wrapper.text()).toContain('No changes');
    });
  });
});
