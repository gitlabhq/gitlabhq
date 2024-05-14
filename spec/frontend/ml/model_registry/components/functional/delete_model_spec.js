import Vue from 'vue';
import VueApollo from 'vue-apollo';
import DeleteModel from '~/ml/model_registry/components/functional/delete_model.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import destroyModelMutation from '~/ml/model_registry/graphql/mutations/destroy_model.mutation.graphql';
import { destroyModelResponses } from 'jest/ml/model_registry/graphql_mock_data';
import { createAlert, VARIANT_DANGER } from '~/alert';

let apolloProvider;
let wrapper;

jest.mock('~/alert');

describe('ml/model_registry/components/functional/delete_model', () => {
  Vue.use(VueApollo);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const createWrapper = ({
    resolver = jest.fn().mockResolvedValue(destroyModelResponses.success),
  } = {}) => {
    const requestHandlers = [[destroyModelMutation, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(DeleteModel, {
      apolloProvider,
      propsData: {
        modelId: 'gid://gitlab/Ml::Model/1234',
      },
      provide: {
        projectPath: 'project/path',
      },
      scopedSlots: {
        default(props) {
          return this.$createElement('button', {
            attrs: {
              'data-testid': 'trigger-button',
            },
            on: {
              click: () => {
                return props.deleteModel();
              },
            },
          });
        },
      },
    });

    return waitForPromises();
  };

  const findButton = () => wrapper.findByTestId('trigger-button');

  const clickButton = async () => {
    await findButton().trigger('click');
    return waitForPromises();
  };

  describe('Model deletion', () => {
    describe('When deletion is successful', () => {
      it('Emits event when successful', async () => {
        const resolver = jest.fn().mockResolvedValue(destroyModelResponses.success);

        createWrapper({ resolver });

        await clickButton();

        expect(resolver).toHaveBeenLastCalledWith({
          id: 'gid://gitlab/Ml::Model/1234',
          projectPath: 'project/path',
        });

        expect(wrapper.emitted('model-deleted')).toHaveLength(1);
      });
    });

    describe('When deletion fails', () => {
      it('shows error message', async () => {
        const error = new Error('Failure!');

        createWrapper({ resolver: jest.fn().mockRejectedValue(error) });

        await clickButton();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to delete model with error: Failure!',
          variant: VARIANT_DANGER,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });

    describe('When deletion results in error', () => {
      it('shows error message', async () => {
        const resolver = jest.fn().mockResolvedValue(destroyModelResponses.failure);

        createWrapper({ resolver });

        await clickButton();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to delete model with error: Model not found',
          variant: VARIANT_DANGER,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });
});
