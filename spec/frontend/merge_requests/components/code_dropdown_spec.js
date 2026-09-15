import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CodeDropdown from '~/merge_requests/components/code_dropdown.vue';

describe('Merge request code dropdown', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CodeDropdown, {
      propsData: {
        patchesPath: '/group/project/-/merge_requests/1.patch',
        plainDiffPath: '/group/project/-/merge_requests/1.diff',
        ...props,
      },
    });
  };

  const findGroups = () => wrapper.findComponent(GlDisclosureDropdown).props('items');
  const findReviewItems = () => findGroups()[0].items;

  it('renders the review and download groups', () => {
    createComponent();

    expect(findGroups()).toEqual([
      {
        name: 'Review changes',
        items: [{ text: 'Check out branch', extraAttrs: { class: 'js-check-out-modal-trigger' } }],
      },
      {
        name: 'Download',
        items: [
          {
            text: 'Patches',
            href: '/group/project/-/merge_requests/1.patch',
            extraAttrs: { download: '', 'data-testid': 'download-email-patches-menu-item' },
          },
          {
            text: 'Plain diff',
            href: '/group/project/-/merge_requests/1.diff',
            extraAttrs: { download: '', 'data-testid': 'download-plain-diff-menu-item' },
          },
        ],
      },
    ]);
  });

  it('renders the Web IDE item when a path is given', () => {
    createComponent({ webIdePath: '/-/ide/project/group/project/merge_requests/1' });

    expect(findReviewItems()[1]).toEqual({
      text: 'Open in Web IDE',
      href: '/-/ide/project/group/project/merge_requests/1',
      extraAttrs: { target: '_blank', 'data-testid': 'open-in-web-ide-button' },
    });
  });

  it('renders the Ona item when a path is given', () => {
    createComponent({ gitpodPath: 'https://ona.example.com#/group/project/-/merge_requests/1' });

    expect(findReviewItems()[1]).toEqual({
      text: 'Open in Ona',
      href: 'https://ona.example.com#/group/project/-/merge_requests/1',
      extraAttrs: { target: '_blank' },
    });
  });

  it('renders the workspace item with its tracking attributes when a path is given', () => {
    createComponent({
      workspacePath: '/-/remote_development/workspaces/new?project=group%2Fproject&gitRef=feature',
      workspaceEventLabel: 'merge_requests:show',
    });

    expect(findReviewItems()[1]).toEqual({
      text: 'Open in Workspace',
      href: '/-/remote_development/workspaces/new?project=group%2Fproject&gitRef=feature',
      extraAttrs: {
        target: '_blank',
        'data-testid': 'open-in-workspace-button',
        'data-event-tracking': 'click_new_workspace_button',
        'data-event-label': 'merge_requests:show',
      },
    });
  });
});
