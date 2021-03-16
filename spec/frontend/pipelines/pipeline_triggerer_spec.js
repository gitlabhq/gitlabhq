import { shallowMount } from '@vue/test-utils';
import pipelineTriggerer from '~/pipelines/components/pipelines_list/pipeline_triggerer.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

describe('Pipelines Triggerer', () => {
  let wrapper;

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  const mockData = {
    pipeline: {
      user: {
        name: 'foo',
        avatar_url: '/avatar',
        path: '/path',
      },
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(pipelineTriggerer, {
      propsData: mockData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render pipeline triggerer table cell', () => {
    expect(wrapper.find('[data-testid="pipeline-triggerer"]').exists()).toBe(true);
  });

  it('should pass triggerer information when triggerer is provided', () => {
    expectComponentWithProps(UserAvatarLink, {
      linkHref: mockData.pipeline.user.path,
      tooltipText: mockData.pipeline.user.name,
      imgSrc: mockData.pipeline.user.avatar_url,
    });
  });

  it('should render "API" when no triggerer is provided', () => {
    wrapper.setProps({
      pipeline: {
        user: null,
      },
    });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('.js-pipeline-url-api').text()).toEqual('API');
    });
  });
});
