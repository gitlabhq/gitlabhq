import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlAvatar } from '@gitlab/ui';
import DiffGutterToggle from '~/rapid_diffs/app/discussions/diff_gutter_toggle.vue';

describe('DiffGutterToggle', () => {
  let wrapper;

  const findCollapseToggle = () => wrapper.find('[data-testid="collapse-toggle"]');
  const findGutterAvatars = () => wrapper.findAll('[data-testid="gutter-avatar"]');
  const findMoreCount = () => wrapper.find('[data-testid="more-count"]');

  const createDiscussion = (overrides = {}) => ({
    id: '1',
    hidden: false,
    notes: [
      {
        id: 'note-1',
        note: 'A comment',
        author: { name: 'Author', avatar_url: 'avatar.png', id: 1 },
      },
    ],
    ...overrides,
  });

  const createComponent = (discussions = [], expanded = true) => {
    wrapper = shallowMount(DiffGutterToggle, {
      propsData: { discussions, expanded },
      attachTo: document.body,
    });
  };

  it('renders nothing when there are no discussions', () => {
    createComponent();
    expect(wrapper.find('[data-gutter-toggle]').exists()).toBe(false);
  });

  it('renders collapse button when discussions are expanded', () => {
    createComponent([createDiscussion()]);
    expect(findCollapseToggle().exists()).toBe(true);
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('collapse');
  });

  it('renders avatars when discussions are collapsed', () => {
    createComponent([createDiscussion()], false);
    expect(findCollapseToggle().exists()).toBe(false);
    expect(wrapper.findAllComponents(GlAvatar)).toHaveLength(1);
  });

  it('renders more count when there are many notes', () => {
    const notes = Array.from({ length: 5 }, (_, i) => ({
      id: `note-${i}`,
      note: `Comment ${i}`,
      author: { name: `Author ${i}`, avatar_url: `avatar${i}.png`, id: i },
    }));
    createComponent([createDiscussion({ notes })], false);
    expect(findGutterAvatars()).toHaveLength(3);
    expect(findMoreCount().text()).toBe('+2');
  });

  it('emits toggle with true when collapse button is clicked', () => {
    createComponent([createDiscussion()]);
    findCollapseToggle().trigger('click');
    expect(wrapper.emitted('toggle')).toStrictEqual([[true]]);
  });

  it('emits toggle with false when avatar is clicked', () => {
    createComponent([createDiscussion()], false);
    wrapper.find('button').trigger('click');
    expect(wrapper.emitted('toggle')).toStrictEqual([[false]]);
  });

  it('retains focus on button after collapsing', async () => {
    createComponent([createDiscussion()]);
    findCollapseToggle().element.focus();
    await findCollapseToggle().trigger('click');
    expect(document.activeElement).toBe(wrapper.find('button').element);
  });

  it('retains focus on button after expanding', async () => {
    createComponent([createDiscussion()], false);
    wrapper.find('button').element.focus();
    await wrapper.find('button').trigger('click');
    expect(document.activeElement).toBe(wrapper.find('button').element);
  });

  it('excludes draft replies from avatars', () => {
    const discussion = createDiscussion({
      notes: [
        { id: 'note-1', note: 'A comment', author: { name: 'Author', avatar_url: 'a.png', id: 1 } },
        {
          id: 'draft-1',
          isDraft: true,
          note: 'Draft',
          author: { name: 'Drafter', avatar_url: 'b.png', id: 2 },
        },
      ],
    });
    createComponent([discussion], false);
    expect(findGutterAvatars()).toHaveLength(1);
  });
});
