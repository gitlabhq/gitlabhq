import { GlDisclosureDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import WorkItemTreeActions from '~/work_items/components/work_item_links/work_item_tree_actions.vue';

describe('WorkItemTreeActions', () => {
  /**
   * @type {import('@vue/test-utils').Wrapper}
   */
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findTooltip = () => getBinding(findDropdown().element, 'gl-tooltip');
  const findDropdownButton = () => findDropdown().find('button');
  const findLink = () => findDropdown().find('a');

  const createComponent = () => {
    wrapper = mount(WorkItemTreeActions, {
      propsData: {
        workItemIid: '2',
        fullPath: 'project/group',
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('contains the correct tooltip text', () => {
    expect(findTooltip().value).toBe('More actions');
  });

  it('does not render the tooltip when the dropdown is shown', async () => {
    await findDropdownButton().trigger('click');

    await nextTick();

    expect(findTooltip().value).toBe('');
  });

  it('contains a link to the roadmap page', () => {
    const link = findLink();

    expect(link.text()).toBe('View on a roadmap');

    expect(link.attributes('href')).toBe('/groups/project/group/-/roadmap?epic_iid=2');
  });
});
