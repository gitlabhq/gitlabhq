import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import dismissUserGroupCalloutMutation from '~/graphql_shared/mutations/dismiss_user_group_callout.mutation.graphql';
import getUserGroupCalloutsQuery from '~/graphql_shared/queries/get_user_group_callouts.query.graphql';
import UserGroupCalloutDismisser from '~/vue_shared/components/user_group_callout_dismisser.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';
import {
  anonUserGroupCalloutsResponse,
  userGroupCalloutMutationResponse,
  userGroupCalloutsResponse,
} from './user_group_callout_dismisser_mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

jest.mock('~/lib/logger', () => ({
  logError: jest.fn(),
}));

const initialSlotProps = (changes = {}) => ({
  dismiss: expect.any(Function),
  shouldShowCallout: false,
  ...changes,
});

describe('UserGroupCalloutDismisser', () => {
  const MOCK_FEATURE_NAME = 'mock_feature_name';
  const MOCK_GROUP_ID = 'gid://gitlab/Group/123';
  const MOCK_NUMERIC_GROUP_ID = 123;

  const successHandlerFactory =
    (dismissedCallouts = []) =>
    () =>
      Promise.resolve(userGroupCalloutsResponse(dismissedCallouts));
  const anonUserHandler = () => Promise.resolve(anonUserGroupCalloutsResponse());
  const errorHandler = () => Promise.reject(new Error('query error'));
  const pendingHandler = () => new Promise(() => {});

  const mutationSuccessHandlerSpy = jest.fn((variables) =>
    Promise.resolve(userGroupCalloutMutationResponse(variables)),
  );
  const mutationErrorHandlerSpy = jest.fn((variables) =>
    Promise.resolve(userGroupCalloutMutationResponse(variables, ['mutation error'])),
  );

  const defaultScopedSlotSpy = jest.fn();

  const callDismissSlotProp = () => defaultScopedSlotSpy.mock.calls[0][0].dismiss();

  const createComponent = ({ queryHandler, mutationHandler, ...options }) => {
    mount(
      UserGroupCalloutDismisser,
      merge(
        {
          propsData: {
            featureName: MOCK_FEATURE_NAME,
            groupId: MOCK_GROUP_ID,
          },
          scopedSlots: {
            default: defaultScopedSlotSpy,
          },
          apolloProvider: createMockApollo([
            [getUserGroupCalloutsQuery, queryHandler],
            [dismissUserGroupCalloutMutation, mutationHandler],
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

  describe('when loaded and not dismissed', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: successHandlerFactory(),
      });

      return waitForPromises();
    });

    it('passes expected slot props to child', () => {
      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
        initialSlotProps({ shouldShowCallout: true }),
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
        initialSlotProps({ shouldShowCallout: false }),
      );
    });

    it('reports errors to Sentry and logs', async () => {
      callDismissSlotProp();

      await waitForPromises();

      expect(logError).toHaveBeenCalledWith(expect.any(Error));
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
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
        initialSlotProps({ shouldShowCallout: false }),
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
        initialSlotProps({ shouldShowCallout: true }),
      );
    });
  });

  describe('dismissing', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

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
          input: { featureName: MOCK_FEATURE_NAME, groupId: MOCK_GROUP_ID },
        });
      });

      it('does not report to Sentry on success', async () => {
        callDismissSlotProp();

        await waitForPromises();

        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('passes expected slot props to child', async () => {
        expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
          initialSlotProps({ shouldShowCallout: true }),
        );

        callDismissSlotProp();

        await nextTick();

        expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
          initialSlotProps({ shouldShowCallout: false }),
        );
      });
    });

    describe('given it fails with GraphQL errors', () => {
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
          input: { featureName: MOCK_FEATURE_NAME, groupId: MOCK_GROUP_ID },
        });
      });

      it('reports GraphQL errors to Sentry', async () => {
        callDismissSlotProp();

        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(
          new Error('User group callout dismissal failed: mutation error'),
        );
      });

      it('passes expected slot props to child', async () => {
        expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
          initialSlotProps({ shouldShowCallout: true }),
        );

        callDismissSlotProp();

        await nextTick();

        expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
          initialSlotProps({ shouldShowCallout: false }),
        );
      });
    });

    describe('given it fails with network/client errors', () => {
      const networkError = new Error('Network error');
      const mutationNetworkErrorHandlerSpy = jest.fn(() => Promise.reject(networkError));

      beforeEach(() => {
        createComponent({
          queryHandler: successHandlerFactory(),
          mutationHandler: mutationNetworkErrorHandlerSpy,
        });

        return waitForPromises();
      });

      it('reports network errors to Sentry and logs', async () => {
        callDismissSlotProp();

        await waitForPromises();

        expect(logError).toHaveBeenCalledWith(networkError);
        expect(Sentry.captureException).toHaveBeenCalledWith(networkError);
      });

      it('passes expected slot props to child', async () => {
        callDismissSlotProp();

        await nextTick();

        expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith(
          initialSlotProps({ shouldShowCallout: false }),
        );
      });
    });
  });

  describe('group ID conversion', () => {
    it('accepts numeric group ID and converts to GraphQL format', async () => {
      createComponent({
        queryHandler: successHandlerFactory(),
        mutationHandler: mutationSuccessHandlerSpy,
        propsData: {
          groupId: MOCK_NUMERIC_GROUP_ID,
        },
      });

      await waitForPromises();
      callDismissSlotProp();

      expect(mutationSuccessHandlerSpy).toHaveBeenCalledWith({
        input: { featureName: MOCK_FEATURE_NAME, groupId: MOCK_GROUP_ID },
      });
    });

    it('accepts GraphQL group ID without conversion', async () => {
      createComponent({
        queryHandler: successHandlerFactory(),
        mutationHandler: mutationSuccessHandlerSpy,
        propsData: {
          groupId: MOCK_GROUP_ID,
        },
      });

      await waitForPromises();
      callDismissSlotProp();

      expect(mutationSuccessHandlerSpy).toHaveBeenCalledWith({
        input: { featureName: MOCK_FEATURE_NAME, groupId: MOCK_GROUP_ID },
      });
    });
  });
});
