import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerNameCell from '~/runner/components/cells/runner_name_cell.vue';

const mockId = '1';
const mockShortSha = '2P6oDVDm';
const mockDescription = 'runner-1';

describe('RunnerTypeCell', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = mount(RunnerNameCell, {
      propsData: {
        runner: {
          id: `gid://gitlab/Ci::Runner/${mockId}`,
          shortSha: mockShortSha,
          description: mockDescription,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays the runner link with id and short token', () => {
    expect(findLink().text()).toBe(`#${mockId} (${mockShortSha})`);
    expect(findLink().attributes('href')).toBe(`/admin/runners/${mockId}`);
  });

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockDescription);
  });
});
