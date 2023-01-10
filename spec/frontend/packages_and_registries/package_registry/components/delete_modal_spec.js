import { GlModal as RealGlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';

const GlModal = stubComponent(RealGlModal, {
  methods: {
    show: jest.fn(),
  },
});

describe('DeleteModal', () => {
  let wrapper;

  const defaultItemsToBeDeleted = [
    {
      name: 'package 01',
    },
    {
      name: 'package 02',
    },
  ];

  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = ({ itemsToBeDeleted = defaultItemsToBeDeleted } = {}) => {
    wrapper = shallowMountExtended(DeleteModal, {
      propsData: {
        itemsToBeDeleted,
      },
      stubs: {
        GlModal,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('passes title prop', () => {
    expect(findModal().props('title')).toMatchInterpolatedText('Delete packages');
  });

  it('passes actionPrimary prop', () => {
    expect(findModal().props('actionPrimary')).toStrictEqual({
      text: 'Permanently delete',
      attributes: [{ variant: 'danger' }, { category: 'primary' }],
    });
  });

  it('renders description', () => {
    expect(findModal().text()).toContain(
      'You are about to delete 2 packages. This operation is irreversible.',
    );
  });

  it('emits confirm when primary event is emitted', () => {
    expect(wrapper.emitted('confirm')).toBeUndefined();

    findModal().vm.$emit('primary');

    expect(wrapper.emitted('confirm')).toHaveLength(1);
  });

  it('emits cancel when cancel event is emitted', () => {
    expect(wrapper.emitted('cancel')).toBeUndefined();

    findModal().vm.$emit('cancel');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('show calls gl-modal show', () => {
    findModal().vm.show();

    expect(GlModal.methods.show).toHaveBeenCalled();
  });
});
