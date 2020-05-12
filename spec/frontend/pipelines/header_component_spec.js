import { shallowMount } from '@vue/test-utils';
import HeaderComponent from '~/pipelines/components/header_component.vue';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import eventHub from '~/pipelines/event_hub';
import { GlModal } from '@gitlab/ui';

describe('Pipeline details header', () => {
  let wrapper;
  let glModalDirective;

  const threeWeeksAgo = new Date();
  threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

  const findDeleteModal = () => wrapper.find(GlModal);

  const defaultProps = {
    pipeline: {
      details: {
        status: {
          group: 'failed',
          icon: 'status_failed',
          label: 'failed',
          text: 'failed',
          details_path: 'path',
        },
      },
      id: 123,
      created_at: threeWeeksAgo.toISOString(),
      user: {
        web_url: 'path',
        name: 'Foo',
        username: 'foobar',
        email: 'foo@bar.com',
        avatar_url: 'link',
      },
      retry_path: 'retry',
      cancel_path: 'cancel',
      delete_path: 'delete',
    },
    isLoading: false,
  };

  const createComponent = (props = {}) => {
    glModalDirective = jest.fn();

    wrapper = shallowMount(HeaderComponent, {
      propsData: {
        ...props,
      },
      directives: {
        glModal: {
          bind(el, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');

    createComponent(defaultProps);
  });

  afterEach(() => {
    eventHub.$off();

    wrapper.destroy();
    wrapper = null;
  });

  it('should render provided pipeline info', () => {
    expect(wrapper.find(CiHeader).props()).toMatchObject({
      status: defaultProps.pipeline.details.status,
      itemId: defaultProps.pipeline.id,
      time: defaultProps.pipeline.created_at,
      user: defaultProps.pipeline.user,
    });
  });

  describe('action buttons', () => {
    it('should not trigger eventHub when nothing happens', () => {
      expect(eventHub.$emit).not.toHaveBeenCalled();
    });

    it('should call postAction when retry button action is clicked', () => {
      wrapper.find('.js-retry-button').vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('headerPostAction', 'retry');
    });

    it('should call postAction when cancel button action is clicked', () => {
      wrapper.find('.js-btn-cancel-pipeline').vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('headerPostAction', 'cancel');
    });

    it('does not show delete modal', () => {
      expect(findDeleteModal()).not.toBeVisible();
    });

    describe('when delete button action is clicked', () => {
      it('displays delete modal', () => {
        expect(findDeleteModal().props('modalId')).toBe(wrapper.vm.$options.DELETE_MODAL_ID);
        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.$options.DELETE_MODAL_ID);
      });

      it('should call delete when modal is submitted', () => {
        findDeleteModal().vm.$emit('ok');

        expect(eventHub.$emit).toHaveBeenCalledWith('headerDeleteAction', 'delete');
      });
    });
  });
});
