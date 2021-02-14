import { GlModal } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';
import createState from '~/vuex_shared/modules/modal/state';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_SLOT = 'Lorem ipsum modal dolar sit.';
const TEST_MODAL_ID = 'my-modal-id';
const TEST_MODULE = 'myModal';

describe('GlModalVuex', () => {
  let wrapper;
  let state;
  let actions;

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      modules: {
        [TEST_MODULE]: {
          namespaced: true,
          state,
          actions,
        },
      },
    });

    const propsData = {
      modalId: TEST_MODAL_ID,
      modalModule: TEST_MODULE,
      ...options.propsData,
    };

    wrapper = shallowMount(GlModalVuex, {
      ...options,
      localVue,
      store,
      propsData,
      stubs: {
        GlModal,
      },
    });
  };

  beforeEach(() => {
    state = createState();

    actions = {
      show: jest.fn(),
      hide: jest.fn(),
    };
  });

  it('renders gl-modal', () => {
    factory({
      slots: {
        default: `<div>${TEST_SLOT}</div>`,
      },
    });
    const glModal = wrapper.find(GlModal);

    expect(glModal.props('modalId')).toBe(TEST_MODAL_ID);
    expect(glModal.text()).toContain(TEST_SLOT);
  });

  it('passes props through to gl-modal', () => {
    const title = 'Test Title';
    const okVariant = 'success';

    factory({
      propsData: {
        title,
        okTitle: title,
        okVariant,
      },
    });
    const glModal = wrapper.find(GlModal);

    expect(glModal.attributes('title')).toEqual(title);
    expect(glModal.attributes('oktitle')).toEqual(title);
    expect(glModal.attributes('okvariant')).toEqual(okVariant);
  });

  it('passes listeners through to gl-modal', () => {
    const ok = jest.fn();

    factory({
      listeners: { ok },
    });

    const glModal = wrapper.find(GlModal);
    glModal.vm.$emit('ok');

    expect(ok).toHaveBeenCalledTimes(1);
  });

  it('calls vuex action on show', () => {
    expect(actions.show).not.toHaveBeenCalled();

    factory();

    const glModal = wrapper.find(GlModal);
    glModal.vm.$emit('shown');

    expect(actions.show).toHaveBeenCalledTimes(1);
  });

  it('calls vuex action on hide', () => {
    expect(actions.hide).not.toHaveBeenCalled();

    factory();

    const glModal = wrapper.find(GlModal);
    glModal.vm.$emit('hidden');

    expect(actions.hide).toHaveBeenCalledTimes(1);
  });

  it('calls bootstrap show when isVisible changes', (done) => {
    state.isVisible = false;

    factory();
    const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

    state.isVisible = true;

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(rootEmit).toHaveBeenCalledWith(BV_SHOW_MODAL, TEST_MODAL_ID);
      })
      .then(done)
      .catch(done.fail);
  });

  it('calls bootstrap hide when isVisible changes', (done) => {
    state.isVisible = true;

    factory();
    const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

    state.isVisible = false;

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(rootEmit).toHaveBeenCalledWith(BV_HIDE_MODAL, TEST_MODAL_ID);
      })
      .then(done)
      .catch(done.fail);
  });

  it.each(['ok', 'cancel'])(
    'passes an "%s" handler to the "modal-footer" slot scope',
    (handlerName) => {
      state.isVisible = true;

      const modalFooterSlotContent = jest.fn();

      factory({
        scopedSlots: {
          'modal-footer': modalFooterSlotContent,
        },
      });

      const handler = modalFooterSlotContent.mock.calls[0][0][handlerName];

      expect(wrapper.emitted(handlerName)).toBeFalsy();
      expect(actions.hide).not.toHaveBeenCalled();

      handler();

      expect(actions.hide).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted(handlerName)).toBeTruthy();
    },
  );
});
