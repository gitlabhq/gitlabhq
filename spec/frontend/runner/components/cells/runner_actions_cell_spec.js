import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerActionCell from '~/runner/components/cells/runner_actions_cell.vue';
import updateRunnerMutation from '~/runner/graphql/update_runner.mutation.graphql';

const mockId = '1';

describe('RunnerTypeCell', () => {
  let wrapper;
  let mutate;

  const findEditBtn = () => wrapper.findByTestId('edit-runner');
  const findToggleActiveBtn = () => wrapper.findByTestId('toggle-active-runner');

  const createComponent = ({ active = true } = {}, options) => {
    wrapper = extendedWrapper(
      shallowMount(RunnerActionCell, {
        propsData: {
          runner: {
            id: `gid://gitlab/Ci::Runner/${mockId}`,
            active,
          },
        },
        mocks: {
          $apollo: {
            mutate,
          },
        },
        ...options,
      }),
    );
  };

  beforeEach(() => {
    mutate = jest.fn();
  });

  afterEach(() => {
    mutate.mockReset();
    wrapper.destroy();
  });

  it('Displays the runner edit link with the correct href', () => {
    createComponent();

    expect(findEditBtn().attributes('href')).toBe('/admin/runners/1');
  });

  describe.each`
    state       | label       | icon       | isActive | newActiveValue
    ${'active'} | ${'Pause'}  | ${'pause'} | ${true}  | ${false}
    ${'paused'} | ${'Resume'} | ${'play'}  | ${false} | ${true}
  `('When the runner is $state', ({ label, icon, isActive, newActiveValue }) => {
    beforeEach(() => {
      mutate.mockResolvedValue({
        data: {
          runnerUpdate: {
            runner: {
              id: `gid://gitlab/Ci::Runner/1`,
              __typename: 'CiRunner',
            },
          },
        },
      });

      createComponent({ active: isActive });
    });

    it(`Displays a ${icon} button`, () => {
      expect(findToggleActiveBtn().props('loading')).toBe(false);
      expect(findToggleActiveBtn().props('icon')).toBe(icon);
      expect(findToggleActiveBtn().attributes('title')).toBe(label);
      expect(findToggleActiveBtn().attributes('aria-label')).toBe(label);
    });

    it(`After clicking the ${icon} button, the button has a loading state`, async () => {
      await findToggleActiveBtn().vm.$emit('click');

      expect(findToggleActiveBtn().props('loading')).toBe(true);
      expect(findToggleActiveBtn().attributes('title')).toBe('');
      expect(findToggleActiveBtn().attributes('aria-label')).toBe('');
    });

    describe(`When clicking on the ${icon} button`, () => {
      beforeEach(async () => {
        await findToggleActiveBtn().vm.$emit('click');
        await waitForPromises();
      });

      it(`The apollo mutation to set active to ${newActiveValue} is called`, () => {
        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith({
          mutation: updateRunnerMutation,
          variables: {
            input: {
              id: `gid://gitlab/Ci::Runner/${mockId}`,
              active: newActiveValue,
            },
          },
        });
      });

      it('The button does not have a loading state', () => {
        expect(findToggleActiveBtn().props('loading')).toBe(false);
      });
    });
  });
});
