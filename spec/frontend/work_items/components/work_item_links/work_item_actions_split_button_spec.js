import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlPopover, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';

const okrActions = [
  {
    name: 'Objective',
    items: [
      {
        text: 'New objective',
      },
      {
        text: 'Existing objective',
      },
    ],
  },
  {
    name: 'Key result',
    items: [
      {
        text: 'New key result',
      },
      {
        text: 'Existing key result',
      },
    ],
  },
];

const okrActionsAtLimit = [
  {
    name: 'Objective',
    atDepthLimit: true,
    items: [
      {
        text: 'New objective',
        extraAttrs: {
          disabled: true,
        },
      },
      {
        text: 'Existing objective',
        extraAttrs: {
          disabled: true,
        },
      },
    ],
  },
];

describe('WorkItemActionsSplitButton', () => {
  let wrapper;

  const createComponent = ({ actions = okrActions } = {}) => {
    wrapper = mountExtended(WorkItemActionsSplitButton, {
      propsData: {
        actions,
      },
      stubs: {
        GlDisclosureDropdown,
      },
    });
  };

  const findAllGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findGroup = (i = 0) => wrapper.findAllComponents(GlDisclosureDropdownGroup).at(i);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);

  it('renders objective and key results sections', () => {
    createComponent();

    expect(findAllGroups()).toHaveLength(okrActions.length);
    expect(findGroup(0).props('group').name).toBe('Objective');
    expect(findGroup(1).props('group').name).toBe('Key result');
    expect(findGroup(0).props('group').items).toEqual([
      expect.objectContaining({ text: 'New objective' }),
      expect.objectContaining({ text: 'Existing objective' }),
    ]);
    expect(findGroup(1).props('group').items).toEqual([
      expect.objectContaining({ text: 'New key result' }),
      expect.objectContaining({ text: 'Existing key result' }),
    ]);
  });

  it('receives correct data if a group reached the limit', () => {
    createComponent({ actions: okrActionsAtLimit });

    expect(findGroup(0).props('group').atDepthLimit).toBe(true);

    findGroup(0)
      .props('group')
      .items.forEach((item) => {
        expect(item.extraAttrs.disabled).toBe(true);
      });
  });

  it('renders popover and info icon if a group reached the limit', () => {
    createComponent({ actions: okrActionsAtLimit });

    expect(findPopover().exists()).toBe(true);
    expect(findInfoIcon().exists()).toBe(true);
  });
});
