import { shallowMount } from '@vue/test-utils';
import MrWidgetMerging from '~/vue_merge_request_widget/components/states/mr_widget_merging.vue';

describe('MRWidgetMerging', () => {
  let wrapper;

  const GlEmoji = { template: '<img />' };
  beforeEach(() => {
    wrapper = shallowMount(MrWidgetMerging, {
      propsData: {
        mr: {
          targetBranchPath: '/branch-path',
          targetBranch: 'branch',
        },
      },
      stubs: {
        GlEmoji,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders information about merge request being merged', () => {
    expect(
      wrapper
        .find('.media-body')
        .text()
        .trim()
        .replace(/\s\s+/g, ' ')
        .replace(/[\r\n]+/g, ' '),
    ).toContain('Merging!');
  });

  it('renders branch information', () => {
    expect(
      wrapper
        .find('.mr-info-list')
        .text()
        .trim()
        .replace(/\s\s+/g, ' ')
        .replace(/[\r\n]+/g, ' '),
    ).toEqual('The changes will be merged into branch');

    expect(wrapper.find('a').attributes('href')).toBe('/branch-path');
  });
});
