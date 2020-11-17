import { GlIcon, GlTooltip } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import StatesTable from '~/terraform/components/states_table.vue';

describe('StatesTable', () => {
  let wrapper;
  useFakeDate([2020, 10, 15]);

  const propsData = {
    states: [
      {
        name: 'state-1',
        lockedAt: '2020-10-13T00:00:00Z',
        lockedByUser: {
          name: 'user-1',
        },
        updatedAt: '2020-10-13T00:00:00Z',
        latestVersion: null,
      },
      {
        name: 'state-2',
        lockedAt: null,
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: null,
      },
      {
        name: 'state-3',
        lockedAt: '2020-10-10T00:00:00Z',
        lockedByUser: {
          name: 'user-2',
        },
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: {
          updatedAt: '2020-10-11T00:00:00Z',
          createdByUser: {
            name: 'user-3',
          },
        },
      },
      {
        name: 'state-4',
        lockedAt: '2020-10-10T00:00:00Z',
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: {
          updatedAt: '2020-10-09T00:00:00Z',
          createdByUser: null,
        },
      },
    ],
  };

  beforeEach(() => {
    wrapper = mount(StatesTable, { propsData });
    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it.each`
    name         | toolTipText                            | locked   | lineNumber
    ${'state-1'} | ${'Locked by user-1 2 days ago'}       | ${true}  | ${0}
    ${'state-2'} | ${null}                                | ${false} | ${1}
    ${'state-3'} | ${'Locked by user-2 5 days ago'}       | ${true}  | ${2}
    ${'state-4'} | ${'Locked by Unknown User 5 days ago'} | ${true}  | ${3}
  `(
    'displays the name and locked information "$name" for line "$lineNumber"',
    ({ name, toolTipText, locked, lineNumber }) => {
      const states = wrapper.findAll('[data-testid="terraform-states-table-name"]');

      const state = states.at(lineNumber);
      const toolTip = state.find(GlTooltip);

      expect(state.text()).toContain(name);
      expect(state.find(GlIcon).exists()).toBe(locked);
      expect(toolTip.exists()).toBe(locked);

      if (locked) {
        expect(toolTip.text()).toMatchInterpolatedText(toolTipText);
      }
    },
  );

  it.each`
    updateTime                     | lineNumber
    ${'updated 2 days ago'}        | ${0}
    ${'updated 5 days ago'}        | ${1}
    ${'user-3 updated 4 days ago'} | ${2}
    ${'updated 6 days ago'}        | ${3}
  `('displays the time "$updateTime" for line "$lineNumber"', ({ updateTime, lineNumber }) => {
    const states = wrapper.findAll('[data-testid="terraform-states-table-updated"]');

    const state = states.at(lineNumber);

    expect(state.text()).toMatchInterpolatedText(updateTime);
  });
});
