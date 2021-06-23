import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerTags from '~/runner/components/runner_tags.vue';

describe('RunnerTags', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays tags text', () => {
    expect(wrapper.text()).toMatchInterpolatedText('tag1 tag2');

    expect(findBadgesAt(0).text()).toBe('tag1');
    expect(findBadgesAt(1).text()).toBe('tag2');
  });

  it('Displays tags with correct style', () => {
    expect(findBadge().props('size')).toBe('md');
    expect(findBadge().props('variant')).toBe('info');
  });

  it('Displays tags with small size', () => {
    createComponent({
      props: { size: 'sm' },
    });

    expect(findBadge().props('size')).toBe('sm');
  });

  it('Is empty when there are no tags', () => {
    createComponent({
      props: { tagList: null },
    });

    expect(wrapper.text()).toBe('');
    expect(findBadge().exists()).toBe(false);
  });
});
