import { mount } from '@vue/test-utils';
import RunnerSummaryCell from '~/runner/components/cells/runner_summary_cell.vue';

const mockId = '1';
const mockShortSha = '2P6oDVDm';
const mockDescription = 'runner-1';

describe('RunnerTypeCell', () => {
  let wrapper;

  const createComponent = (options) => {
    wrapper = mount(RunnerSummaryCell, {
      propsData: {
        runner: {
          id: `gid://gitlab/Ci::Runner/${mockId}`,
          shortSha: mockShortSha,
          description: mockDescription,
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

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockDescription);
  });

  it('Displays a custom slot', () => {
    const slotContent = 'My custom runner summary';

    createComponent({
      slots: {
        'runner-name': slotContent,
      },
    });

    expect(wrapper.text()).toContain(slotContent);
  });
});
