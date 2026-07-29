import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/container_registry/explorer/components/delete_image.vue';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/container_registry/explorer/constants/index';
import deleteContainerRepositoryMutation from '~/packages_and_registries/container_registry/explorer/graphql/mutations/delete_container_repository.mutation.graphql';
import getContainerRepositoryDetailsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_details.query.graphql';
import {
  containerRepositoryMock,
  deletedContainerRepository,
  graphQLImageDeleteMock,
  graphQLImageDeleteMockError,
} from '../mock_data';

Vue.use(VueApollo);

describe('Delete Image', () => {
  let wrapper;
  let apolloProvider;

  const { id } = containerRepositoryMock;

  const cacheVariables = { id, first: GRAPHQL_PAGE_SIZE };

  const findButton = () => wrapper.find('button');
  const doDelete = () => findButton().trigger('click');

  const readImageDetailsFromCache = () =>
    apolloProvider.defaultClient.readQuery({
      query: getContainerRepositoryDetailsQuery,
      variables: cacheVariables,
    });

  const mountComponent = ({
    propsData = { id },
    handler = jest.fn().mockResolvedValue(graphQLImageDeleteMock),
    seedCache = false,
  } = {}) => {
    apolloProvider = createMockApollo([[deleteContainerRepositoryMutation, handler]]);

    if (seedCache) {
      apolloProvider.defaultClient.writeQuery({
        query: getContainerRepositoryDetailsQuery,
        variables: cacheVariables,
        data: {
          containerRepository: {
            ...containerRepositoryMock,
            __typename: 'ContainerRepositoryDetails',
          },
        },
      });
    }

    wrapper = shallowMount(component, {
      propsData,
      apolloProvider,
      scopedSlots: {
        default: '<button @click="props.doDelete">test</button>',
      },
    });

    return handler;
  };

  afterEach(() => {
    apolloProvider = null;
  });

  it('executes apollo mutate on doDelete', async () => {
    const handler = mountComponent();

    await doDelete();
    await waitForPromises();

    expect(handler).toHaveBeenCalledWith({ id });
  });

  it('on success emits the correct events', async () => {
    mountComponent();

    await doDelete();
    await waitForPromises();

    expect(wrapper.emitted('start')).toEqual([[]]);
    expect(wrapper.emitted('success')).toEqual([[]]);
    expect(wrapper.emitted('end')).toEqual([[]]);
  });

  it('when a payload contains an error emits an error event', async () => {
    mountComponent({ handler: jest.fn().mockResolvedValue(graphQLImageDeleteMockError) });

    await doDelete();
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[['foo']]]);
  });

  it('when the api call errors emits an error event', async () => {
    mountComponent({ handler: jest.fn().mockRejectedValue(new Error('error')) });

    await doDelete();
    await waitForPromises();

    expect(wrapper.emitted('error')[0][0]).toEqual([
      expect.objectContaining({ message: expect.stringContaining('error') }),
    ]);
  });

  it('leaves the cached image status untouched when `useUpdateFn` is false', async () => {
    mountComponent({ seedCache: true });

    await doDelete();
    await waitForPromises();

    expect(readImageDetailsFromCache().containerRepository.status).toBe(
      containerRepositoryMock.status,
    );
  });

  it('updateImageStatus reads and writes the image status to the cache', async () => {
    mountComponent({ propsData: { id, useUpdateFn: true }, seedCache: true });

    expect(readImageDetailsFromCache().containerRepository.status).toBe(
      containerRepositoryMock.status,
    );

    await doDelete();
    await waitForPromises();

    expect(readImageDetailsFromCache().containerRepository.status).toBe(
      deletedContainerRepository.status,
    );
  });

  it('binds the doDelete function to the default scoped slot', async () => {
    const handler = mountComponent();

    await doDelete();
    await waitForPromises();

    expect(handler).toHaveBeenCalled();
  });
});
