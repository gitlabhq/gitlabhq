import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import getUserCalloutsQuery from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import {
  anonUserCalloutsResponse,
  userCalloutMutationResponse,
  userCalloutsResponse,
} from './user_callout_dismisser_mock_data';

Vue.use(VueApollo);

const initialSlotProps = (changes = {}) => ({
  dismiss: expect.any(Function),
  isAnonUser: false,
  isDismissed: false,
  isLoadingQuery: true,
  isLoadingMutation: false,
  mutationError: null,
  queryError: null,
  shouldShowCallout: false,
  ...changes,
});

describe('UserCalloutDismisser', () => {
  let wrapper;

  const MOCK_FEATURE_NAME = 'mock_feature_name';

  // Query handlers
  const successHandlerFactory = (dismissedCallouts = []) => async () =>
    userCalloutsResponse(dismissedCallouts);
  const anonUserHandler = async () => anonUserCalloutsResponse();
  const errorHandler = () => Promise.reject(new Error('query error'));
  const pendingHandler = () => new Promise(() => {});

  // Mutation handlers
  const mutationSuccessHandlerSpy = jest.fn(async (variables) =>
    userCalloutMutationResponse(variables),
  );
  const mutationErrorHandlerSpy = jest.fn(async (variables) =>
    userCalloutMutationResponse(variables, ['mutation error']),
  );

  const defaultScopedSlotSpy = jest.fn();

  const callDismissSlotProp = () => defaultScopedSlotSpy.mock.calls[0][0].dismiss();

  const createComponent = ({ queryHandler, mutationHandler, ...options }) => {
    wrapper = mount(
      UserCalloutDismisser,
      merge(
        {
          propsData: {
            featureName: MOCK_FEATURE_NAME,
          },
          scopedSlots: {
            default: defaultScopedSlotSpy,
          },
          apolloProvider: createMockApollo([
            [getUserCalloutsQuery, queryHandler],
            [dismissUserCalloutMutation, mutationHandler],
          ]),
        },
        options,
      ),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: pendingHandler,
      });
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(initialSlotProps());
    });
  });

  describe('when loaded and dismissed', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: successHandlerFactory([MOCK_FEATURE_NAME]),
      });

      return waitForPromises();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(
        initialSlotProps({
          isDismissed: true,
          isLoadingQuery: false,
        }),
      );
    });
  });

  describe('when loaded and not dismissed', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: successHandlerFactory(),
      });

      return waitForPromises();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(
        initialSlotProps({
          isLoadingQuery: false,
          shouldShowCallout: true,
        }),
      );
    });
  });

  describe('when loaded with errors', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: errorHandler,
      });

      return waitForPromises();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(
        initialSlotProps({
          isLoadingQuery: false,
          queryError: expect.any(Error),
        }),
      );
    });
  });

  describe('when loaded and the user is anonymous', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: anonUserHandler,
      });

      return waitForPromises();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(
        initialSlotProps({
          isAnonUser: true,
          isLoadingQuery: false,
        }),
      );
    });
  });

  describe('when skipQuery is true', () => {
    let queryHandler;
    beforeEach(() => {
      queryHandler = jest.fn();

      createComponent({
        queryHandler,
        propsData: {
          skipQuery: true,
        },
      });
    });

    it('does not run the query', async () => {
      expect(queryHandler).not.toHaveBeenCalled();

      await waitForPromises();

      expect(queryHandler).not.toHaveBeenCalled();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).lastCalledWith(
        initialSlotProps({
          isLoadingQuery: false,
          shouldShowCallout: true,
        }),
      );
    });
  });

  describe('dismissing', () => {
    describe('given it succeeds', () => {
      beforeEach(() => {
        createComponent({
          queryHandler: successHandlerFactory(),
          mutationHandler: mutationSuccessHandlerSpy,
        });

        return waitForPromises();
      });

      it('dismissing calls mutation', () => {
        expect(mutationSuccessHandlerSpy).not.toHaveBeenCalled();

        callDismissSlotProp();

        expect(mutationSuccessHandlerSpy).toHaveBeenCalledWith({
          input: { featureName: MOCK_FEATURE_NAME },
        });
      });

      it('passes expected slot props to child', async () => {
        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isLoadingQuery: false,
            shouldShowCallout: true,
          }),
        );

        callDismissSlotProp();

        // Wait for Vue re-render due to prop change
        await nextTick();

        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isDismissed: true,
            isLoadingMutation: true,
            isLoadingQuery: false,
          }),
        );

        // Wait for mutation to resolve
        await waitForPromises();

        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isDismissed: true,
            isLoadingQuery: false,
          }),
        );
      });
    });

    describe('given it fails', () => {
      beforeEach(() => {
        createComponent({
          queryHandler: successHandlerFactory(),
          mutationHandler: mutationErrorHandlerSpy,
        });

        return waitForPromises();
      });

      it('calls mutation', () => {
        expect(mutationErrorHandlerSpy).not.toHaveBeenCalled();

        callDismissSlotProp();

        expect(mutationErrorHandlerSpy).toHaveBeenCalledWith({
          input: { featureName: MOCK_FEATURE_NAME },
        });
      });

      it('passes expected slot props to child', async () => {
        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isLoadingQuery: false,
            shouldShowCallout: true,
          }),
        );

        callDismissSlotProp();

        // Wait for Vue re-render due to prop change
        await nextTick();

        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isDismissed: true,
            isLoadingMutation: true,
            isLoadingQuery: false,
          }),
        );

        // Wait for mutation to resolve
        await waitForPromises();

        expect(defaultScopedSlotSpy).lastCalledWith(
          initialSlotProps({
            isDismissed: true,
            isLoadingQuery: false,
            mutationError: ['mutation error'],
          }),
        );
      });
    });
  });
});
