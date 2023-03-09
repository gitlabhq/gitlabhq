import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/container_registry/explorer/components/delete_image.vue';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/container_registry/explorer/constants/index';
import deleteContainerRepositoryMutation from '~/packages_and_registries/container_registry/explorer/graphql/mutations/delete_container_repository.mutation.graphql';
import getContainerRepositoryDetailsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_details.query.graphql';

describe('Delete Image', () => {
  let wrapper;
  const id = '1';
  const storeMock = {
    readQuery: jest.fn().mockReturnValue({
      containerRepository: {
        status: 'foo',
      },
    }),
    writeQuery: jest.fn(),
  };

  const updatePayload = {
    data: {
      destroyContainerRepository: {
        containerRepository: {
          status: 'baz',
        },
      },
    },
  };

  const findButton = () => wrapper.find('button');

  const mountComponent = ({
    propsData = { id },
    mutate = jest.fn().mockResolvedValue({}),
  } = {}) => {
    wrapper = shallowMount(component, {
      propsData,
      mocks: {
        $apollo: {
          mutate,
        },
      },
      scopedSlots: {
        default: '<button @click="props.doDelete">test</button>',
      },
    });
  };

  it('executes apollo mutate on doDelete', () => {
    const mutate = jest.fn().mockResolvedValue({});
    mountComponent({ mutate });

    wrapper.vm.doDelete();

    expect(mutate).toHaveBeenCalledWith({
      mutation: deleteContainerRepositoryMutation,
      variables: {
        id,
      },
      update: undefined,
    });
  });

  it('on success emits the correct events', async () => {
    const mutate = jest.fn().mockResolvedValue({});
    mountComponent({ mutate });

    wrapper.vm.doDelete();

    await waitForPromises();

    expect(wrapper.emitted('start')).toEqual([[]]);
    expect(wrapper.emitted('success')).toEqual([[]]);
    expect(wrapper.emitted('end')).toEqual([[]]);
  });

  it('when a payload contains an error emits an error event', async () => {
    const mutate = jest
      .fn()
      .mockResolvedValue({ data: { destroyContainerRepository: { errors: ['foo'] } } });

    mountComponent({ mutate });
    wrapper.vm.doDelete();

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[['foo']]]);
  });

  it('when the api call errors emits an error event', async () => {
    const mutate = jest.fn().mockRejectedValue('error');

    mountComponent({ mutate });
    wrapper.vm.doDelete();

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[['error']]]);
  });

  it('uses the update function, when the prop is set to true', () => {
    const mutate = jest.fn().mockResolvedValue({});

    mountComponent({ mutate, propsData: { id, useUpdateFn: true } });
    wrapper.vm.doDelete();

    expect(mutate).toHaveBeenCalledWith({
      mutation: deleteContainerRepositoryMutation,
      variables: {
        id,
      },
      update: wrapper.vm.updateImageStatus,
    });
  });

  it('updateImage status reads and write to the cache', () => {
    mountComponent();

    const variables = {
      id,
      first: GRAPHQL_PAGE_SIZE,
    };

    wrapper.vm.updateImageStatus(storeMock, updatePayload);

    expect(storeMock.readQuery).toHaveBeenCalledWith({
      query: getContainerRepositoryDetailsQuery,
      variables,
    });
    expect(storeMock.writeQuery).toHaveBeenCalledWith({
      query: getContainerRepositoryDetailsQuery,
      variables,
      data: {
        containerRepository: {
          status: updatePayload.data.destroyContainerRepository.containerRepository.status,
        },
      },
    });
  });

  it('binds the doDelete function to the default scoped slot', () => {
    const mutate = jest.fn().mockResolvedValue({});
    mountComponent({ mutate });
    findButton().trigger('click');
    expect(mutate).toHaveBeenCalled();
  });
});
