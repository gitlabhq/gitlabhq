import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerActionCell from '~/runner/components/cells/runner_actions_cell.vue';
import deleteRunnerMutation from '~/runner/graphql/delete_runner.mutation.graphql';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import runnerUpdateMutation from '~/runner/graphql/runner_update.mutation.graphql';

const mockId = '1';

const getRunnersQueryName = getRunnersQuery.definitions[0].name.value;

describe('RunnerTypeCell', () => {
  let wrapper;
  let mutate;

  const findEditBtn = () => wrapper.findByTestId('edit-runner');
  const findToggleActiveBtn = () => wrapper.findByTestId('toggle-active-runner');
  const findDeleteBtn = () => wrapper.findByTestId('delete-runner');

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
    });

    it(`After the ${icon} button is clicked, stale tooltip is removed`, async () => {
      await findToggleActiveBtn().vm.$emit('click');

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
          mutation: runnerUpdateMutation,
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

  describe('When the user clicks a runner', () => {
    beforeEach(() => {
      createComponent();

      mutate.mockResolvedValue({
        data: {
          runnerDelete: {
            runner: {
              id: `gid://gitlab/Ci::Runner/1`,
              __typename: 'CiRunner',
            },
          },
        },
      });

      jest.spyOn(window, 'confirm');
    });

    describe('When the user confirms deletion', () => {
      beforeEach(async () => {
        window.confirm.mockReturnValue(true);
        await findDeleteBtn().vm.$emit('click');
      });

      it('The user sees a confirmation alert', async () => {
        expect(window.confirm).toHaveBeenCalledTimes(1);
        expect(window.confirm).toHaveBeenCalledWith(expect.any(String));
      });

      it('The delete mutation is called correctly', () => {
        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith({
          mutation: deleteRunnerMutation,
          variables: {
            input: {
              id: `gid://gitlab/Ci::Runner/${mockId}`,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: [getRunnersQueryName],
        });
      });

      it('The delete button does not have a loading state', () => {
        expect(findDeleteBtn().props('loading')).toBe(false);
        expect(findDeleteBtn().attributes('title')).toBe('Remove');
      });

      it('After the delete button is clicked, loading state is shown', async () => {
        await findDeleteBtn().vm.$emit('click');

        expect(findDeleteBtn().props('loading')).toBe(true);
      });

      it('After the delete button is clicked, stale tooltip is removed', async () => {
        await findDeleteBtn().vm.$emit('click');

        expect(findDeleteBtn().attributes('title')).toBe('');
      });
    });

    describe('When the user does not confirm deletion', () => {
      beforeEach(async () => {
        window.confirm.mockReturnValue(false);
        await findDeleteBtn().vm.$emit('click');
      });

      it('The user sees a confirmation alert', () => {
        expect(window.confirm).toHaveBeenCalledTimes(1);
      });

      it('The delete mutation is not called', () => {
        expect(mutate).toHaveBeenCalledTimes(0);
      });

      it('The delete button does not have a loading state', () => {
        expect(findDeleteBtn().props('loading')).toBe(false);
        expect(findDeleteBtn().attributes('title')).toBe('Remove');
      });
    });
  });
});
