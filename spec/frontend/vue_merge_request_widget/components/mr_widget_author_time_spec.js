import { shallowMount } from '@vue/test-utils';
import MrWidgetAuthor from '~/vue_merge_request_widget/components/mr_widget_author.vue';
import MrWidgetAuthorTime from '~/vue_merge_request_widget/components/mr_widget_author_time.vue';

describe('MrWidgetAuthorTime', () => {
  let wrapper;

  const defaultProps = {
    actionText: 'Merged by',
    author: {
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://localhost:3000/root',
      avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    },
    dateTitle: '2017-03-23T23:02:00.807Z',
    dateReadable: '12 hours ago',
  };

  beforeEach(() => {
    wrapper = shallowMount(MrWidgetAuthorTime, {
      propsData: defaultProps,
    });
  });

  it('renders provided action text', () => {
    expect(wrapper.text()).toContain('Merged by');
  });

  it('renders author', () => {
    expect(wrapper.findComponent(MrWidgetAuthor).props('author')).toStrictEqual(
      defaultProps.author,
    );
  });

  it('renders provided time', () => {
    expect(wrapper.find('time').attributes('title')).toBe('2017-03-23T23:02:00.807Z');

    expect(wrapper.find('time').text().trim()).toBe('12 hours ago');
  });
});
