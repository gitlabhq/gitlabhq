import { GlIcon } from '@gitlab/ui';
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
        updatedAt: '2020-10-13T00:00:00Z',
      },
      {
        name: 'state-2',
        lockedAt: null,
        updatedAt: '2020-10-10T00:00:00Z',
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
    stateName    | locked   | lineNumber
    ${'state-1'} | ${true}  | ${0}
    ${'state-2'} | ${false} | ${1}
  `(
    'displays the name "$stateName" for line "$lineNumber"',
    ({ stateName, locked, lineNumber }) => {
      const states = wrapper.findAll('[data-testid="terraform-states-table-name"]');

      const state = states.at(lineNumber);

      expect(state.text()).toContain(stateName);
      expect(state.find(GlIcon).exists()).toBe(locked);
    },
  );

  it.each`
    updateTime              | lineNumber
    ${'updated 2 days ago'} | ${0}
    ${'updated 5 days ago'} | ${1}
  `('displays the time "$updateTime" for line "$lineNumber"', ({ updateTime, lineNumber }) => {
    const states = wrapper.findAll('[data-testid="terraform-states-table-updated"]');

    const state = states.at(lineNumber);

    expect(state.text()).toBe(updateTime);
  });
});
