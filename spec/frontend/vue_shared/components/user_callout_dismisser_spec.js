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
  shouldShowCallout: false,
  ...changes,
});

describe('UserCalloutDismisser', () => {
  const MOCK_FEATURE_NAME = 'mock_feature_name';

  // Query handlers
  const successHandlerFactory =
    (dismissedCallouts = []) =>
    () =>
      Promise.resolve(userCalloutsResponse(dismissedCallouts));
  const anonUserHandler = () => Promise.resolve(anonUserCalloutsResponse());
  const errorHandler = () => Promise.reject(new Error('query error'));
  const pendingHandler = () => new Promise(() => {});

  // Mutation handlers
  const mutationSuccessHandlerSpy = jest.fn((variables) =>
    Promise.resolve(userCalloutMutationResponse(variables)),
  );

  const defaultScopedSlotSpy = jest.fn();

  const callDismissSlotProp = () => defaultScopedSlotSpy.mock.calls[0][0].dismiss();

  const createComponent = ({ queryHandler, mutationHandler, ...options }) => {
    mount(
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

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: pendingHandler,
      });
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(initialSlotProps());
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
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({
          shouldShowCallout: false,
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
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({
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
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({
          shouldShowCallout: false,
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
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({
          shouldShowCallout: false,
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
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({
          shouldShowCallout: true,
        }),
      );
    });
  });

  describe('dismissing', () => {
    const queryHandler = jest.fn(successHandlerFactory());

    beforeEach(() => {
      createComponent({
        queryHandler,
        mutationHandler: mutationSuccessHandlerSpy,
      });

      return waitForPromises();
    });

    it('calls mutation and updates slotProps.shouldShowCallout', async () => {
      expect(mutationSuccessHandlerSpy).not.toHaveBeenCalled();
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        expect.objectContaining({ shouldShowCallout: true }),
      );

      callDismissSlotProp();
      await nextTick();

      expect(mutationSuccessHandlerSpy).toHaveBeenCalledWith({
        input: { featureName: MOCK_FEATURE_NAME },
      });
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        expect.objectContaining({ shouldShowCallout: false }),
      );
    });

    it('refetches query after mutation', async () => {
      expect(queryHandler).toHaveBeenCalledTimes(1);

      callDismissSlotProp();
      await waitForPromises();

      expect(queryHandler).toHaveBeenCalledTimes(2);
    });
  });
});
