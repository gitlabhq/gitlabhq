import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';

describe('RunnerTags', () => {
  let wrapper;

  const findBadgesAt = (i = 0) => wrapper.findAllComponents(GlBadge).at(i);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mount(RunnerTags, {
      propsData: {
        tagList: ['tag1', 'tag2'],
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays tags text', () => {
    expect(wrapper.text()).toMatchInterpolatedText('tag1 tag2');

    expect(findBadgesAt(0).text()).toBe('tag1');
    expect(findBadgesAt(1).text()).toBe('tag2');
  });

  it('Is empty when there are no tags', () => {
    createComponent({
      props: { tagList: null },
    });

    expect(wrapper.text()).toEqual('');
  });
});
