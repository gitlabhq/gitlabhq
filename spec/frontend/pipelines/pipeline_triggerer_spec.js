import { shallowMount } from '@vue/test-utils';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import pipelineTriggerer from '~/pipelines/components/pipeline_triggerer.vue';

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
      attachToDocument: true,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a table cell', () => {
    expect(wrapper.contains('.table-section')).toBe(true);
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
