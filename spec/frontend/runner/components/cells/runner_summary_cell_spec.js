import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerSummaryCell from '~/runner/components/cells/runner_summary_cell.vue';
import { INSTANCE_TYPE, PROJECT_TYPE } from '~/runner/constants';

const mockId = '1';
const mockShortSha = '2P6oDVDm';
const mockDescription = 'runner-1';
const mockIpAddress = '0.0.0.0';

describe('RunnerTypeCell', () => {
  let wrapper;

  const findLockIcon = () => wrapper.findByTestId('lock-icon');

  const createComponent = (runner, options) => {
    wrapper = mountExtended(RunnerSummaryCell, {
      propsData: {
        runner: {
          id: `gid://gitlab/Ci::Runner/${mockId}`,
          shortSha: mockShortSha,
          description: mockDescription,
          ipAddress: mockIpAddress,
          runnerType: INSTANCE_TYPE,
          ...runner,
        },
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays the runner name as id and short token', () => {
    expect(wrapper.text()).toContain(`#${mockId} (${mockShortSha})`);
  });

  it('Displays the runner type', () => {
    expect(wrapper.text()).toContain('shared');
  });

  it('Does not display the locked icon', () => {
    expect(findLockIcon().exists()).toBe(false);
  });

  it('Displays the locked icon for locked runners', () => {
    createComponent({
      runnerType: PROJECT_TYPE,
      locked: true,
    });

    expect(findLockIcon().exists()).toBe(true);
  });

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockDescription);
  });

  it('Displays ip address', () => {
    expect(wrapper.text()).toContain(`${__('IP Address')} ${mockIpAddress}`);
  });

  it('Displays no ip address', () => {
    createComponent({
      ipAddress: null,
    });

    expect(wrapper.text()).not.toContain(__('IP Address'));
  });

  it('Displays a custom slot', () => {
    const slotContent = 'My custom runner summary';

    createComponent(
      {},
      {
        slots: {
          'runner-name': slotContent,
        },
      },
    );

    expect(wrapper.text()).toContain(slotContent);
  });
});
