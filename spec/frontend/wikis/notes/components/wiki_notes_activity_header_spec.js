import { shallowMount } from '@vue/test-utils';
import WikiDiscussionSorter from '~/wikis/wiki_notes/components/wiki_discussion_sorter.vue';
import WikiNotesActivityHeader from '~/wikis/wiki_notes/components/wiki_notes_activity_header.vue';

describe('Wiki Notes Activity Header', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(WikiNotesActivityHeader);
  };

  beforeEach(createComponent);

  it('renders without crashing', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('shows the expected heading', () => {
    expect(wrapper.find('h2').text()).toBe('Comments');
  });

  it('displays the WikiDiscussionSorter', () => {
    expect(wrapper.findComponent(WikiDiscussionSorter).exists()).toBe(true);
  });
});
