import { GlBadge, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import StatesTable from '~/terraform/components/states_table.vue';
import StateActions from '~/terraform/components/states_table_actions.vue';

describe('StatesTable', () => {
  let wrapper;
  useFakeDate([2020, 10, 15]);

  const defaultProps = {
    states: [
      {
        _showDetails: true,
        errorMessages: ['State 1 has errored'],
        name: 'state-1',
        loadingLock: false,
        loadingRemove: false,
        lockedAt: '2020-10-13T00:00:00Z',
        lockedByUser: {
          name: 'user-1',
        },
        updatedAt: '2020-10-13T00:00:00Z',
        latestVersion: null,
      },
      {
        _showDetails: false,
        errorMessages: [],
        name: 'state-2',
        loadingLock: true,
        loadingRemove: false,
        lockedAt: null,
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: null,
      },
      {
        _showDetails: false,
        errorMessages: [],
        name: 'state-3',
        loadingLock: true,
        loadingRemove: false,
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
          job: {
            detailedStatus: {
              detailsPath: '/job-path-3',
              group: 'failed',
              icon: 'status_failed',
              label: 'failed',
              text: 'failed',
            },
            pipeline: {
              id: 'gid://gitlab/Ci::Pipeline/3',
              path: '/pipeline-path-3',
            },
          },
        },
      },
      {
        _showDetails: true,
        errorMessages: ['State 4 has errored'],
        name: 'state-4',
        loadingLock: false,
        loadingRemove: false,
        lockedAt: '2020-10-10T00:00:00Z',
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: {
          updatedAt: '2020-10-09T00:00:00Z',
          createdByUser: null,
          job: {
            detailedStatus: {
              detailsPath: '/job-path-4',
              group: 'passed',
              icon: 'status_success',
              label: 'passed',
              text: 'passed',
            },
            pipeline: {
              id: 'gid://gitlab/Ci::Pipeline/4',
              path: '/pipeline-path-4',
            },
          },
        },
      },
      {
        _showDetails: false,
        errorMessages: [],
        name: 'state-5',
        loadingLock: false,
        loadingRemove: true,
        lockedAt: null,
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        latestVersion: null,
      },
      {
        _showDetails: false,
        errorMessages: [],
        name: 'state-6',
        loadingLock: false,
        loadingRemove: false,
        lockedAt: null,
        lockedByUser: null,
        updatedAt: '2020-10-10T00:00:00Z',
        deletedAt: '2022-02-02T00:00:00Z',
        latestVersion: null,
      },
    ],
  };

  const createComponent = async (propsData = defaultProps) => {
    wrapper = extendedWrapper(
      mount(StatesTable, {
        propsData,
        provide: { projectPath: 'path/to/project' },
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
      }),
    );
    await nextTick();
  };

  const findActions = () => wrapper.findAllComponents(StateActions);

  beforeEach(() => {
    return createComponent();
  });

  it.each`
    name         | toolTipText                            | hasBadge | loading  | lineNumber
    ${'state-1'} | ${'Locked by user-1 2 days ago'}       | ${true}  | ${false} | ${0}
    ${'state-2'} | ${'Locking state'}                     | ${false} | ${true}  | ${1}
    ${'state-3'} | ${'Unlocking state'}                   | ${false} | ${true}  | ${2}
    ${'state-4'} | ${'Locked by Unknown User 5 days ago'} | ${true}  | ${false} | ${3}
    ${'state-5'} | ${'Removing'}                          | ${false} | ${true}  | ${4}
    ${'state-6'} | ${'Deletion in progress'}              | ${true}  | ${false} | ${5}
  `(
    'displays the name and locked information "$name" for line "$lineNumber"',
    ({ name, toolTipText, hasBadge, loading, lineNumber }) => {
      const states = wrapper.findAll('[data-testid="terraform-states-table-name"]');
      const state = states.at(lineNumber);

      expect(state.text()).toContain(name);
      expect(state.findComponent(GlBadge).exists()).toBe(hasBadge);
      expect(state.findComponent(GlLoadingIcon).exists()).toBe(loading);

      if (hasBadge) {
        const badge = wrapper.findByTestId(`state-badge-${name}`);

        expect(getBinding(badge.element, 'gl-tooltip')).toBeDefined();
        expect(badge.attributes('title')).toMatchInterpolatedText(toolTipText);
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

  it.each`
    pipelineText              | toolTipAdded | lineNumber
    ${''}                     | ${false}     | ${0}
    ${''}                     | ${false}     | ${1}
    ${'#3 failed Job status'} | ${true}      | ${2}
    ${'#4 passed Job status'} | ${true}      | ${3}
  `(
    'displays the pipeline information for line "$lineNumber"',
    ({ pipelineText, toolTipAdded, lineNumber }) => {
      const states = wrapper.findAll('[data-testid="terraform-states-table-pipeline"]');
      const state = states.at(lineNumber);

      expect(state.findComponent(GlTooltip).exists()).toBe(toolTipAdded);
      expect(state.text()).toMatchInterpolatedText(pipelineText);
    },
  );

  it.each`
    errorMessage                               | lineNumber
    ${defaultProps.states[0].errorMessages[0]} | ${0}
    ${defaultProps.states[3].errorMessages[0]} | ${1}
  `('displays table error message "$errorMessage"', ({ errorMessage, lineNumber }) => {
    const states = wrapper.findAll('[data-testid="terraform-states-table-error"]');
    const state = states.at(lineNumber);

    expect(state.text()).toBe(errorMessage);
  });

  it('displays an actions dropdown for each state', () => {
    beforeEach(() => {
      return createComponent();
    });

    expect(findActions().length).toEqual(defaultProps.states.length);
  });
});
