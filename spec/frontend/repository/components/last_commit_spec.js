import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LastCommit from '~/repository/components/last_commit.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

let vm;

function createCommitData(data = {}) {
  const defaultData = {
    sha: '123456789',
    title: 'Commit title',
    titleHtml: 'Commit title',
    message: 'Commit message',
    webPath: '/commit/123',
    authoredDate: '2019-01-01',
    author: {
      name: 'Test',
      avatarUrl: 'https://test.com',
      webPath: '/test',
    },
    pipeline: {
      detailedStatus: {
        detailsPath: 'https://test.com/pipeline',
        icon: 'failed',
        tooltip: 'failed',
        text: 'failed',
        group: {},
      },
    },
  };
  return Object.assign(defaultData, data);
}

function factory(commit = createCommitData(), loading = false) {
  vm = shallowMount(LastCommit, {
    mocks: {
      $apollo: {
        queries: {
          commit: {
            loading: true,
          },
        },
      },
    },
  });
  vm.setData({ commit });
  vm.vm.$apollo.queries.commit.loading = loading;
}

const emptyMessageClass = 'font-italic';

describe('Repository last commit component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it.each`
    loading  | label
    ${true}  | ${'shows'}
    ${false} | ${'hides'}
  `('$label when loading icon $loading is true', async ({ loading }) => {
    factory(createCommitData(), loading);

    await vm.vm.$nextTick();

    expect(vm.find(GlLoadingIcon).exists()).toBe(loading);
  });

  it('renders commit widget', async () => {
    factory();

    await vm.vm.$nextTick();

    expect(vm.element).toMatchSnapshot();
  });

  it('renders short commit ID', async () => {
    factory();

    await vm.vm.$nextTick();

    expect(vm.find('[data-testid="last-commit-id-label"]').text()).toEqual('12345678');
  });

  it('hides pipeline components when pipeline does not exist', async () => {
    factory(createCommitData({ pipeline: null }));

    await vm.vm.$nextTick();

    expect(vm.find('.js-commit-pipeline').exists()).toBe(false);
  });

  it('renders pipeline components', async () => {
    factory();

    await vm.vm.$nextTick();

    expect(vm.find('.js-commit-pipeline').exists()).toBe(true);
  });

  it('hides author component when author does not exist', async () => {
    factory(createCommitData({ author: null }));

    await vm.vm.$nextTick();

    expect(vm.find('.js-user-link').exists()).toBe(false);
    expect(vm.find(UserAvatarLink).exists()).toBe(false);
  });

  it('does not render description expander when description is null', async () => {
    factory(createCommitData({ descriptionHtml: null }));

    await vm.vm.$nextTick();

    expect(vm.find('.text-expander').exists()).toBe(false);
    expect(vm.find('.commit-row-description').exists()).toBe(false);
  });

  it('expands commit description when clicking expander', async () => {
    factory(createCommitData({ descriptionHtml: 'Test description' }));

    await vm.vm.$nextTick();

    vm.find('.text-expander').vm.$emit('click');

    await vm.vm.$nextTick();

    expect(vm.find('.commit-row-description').isVisible()).toBe(true);
    expect(vm.find('.text-expander').classes('open')).toBe(true);
  });

  it('strips the first newline of the description', async () => {
    factory(createCommitData({ descriptionHtml: '&#x000A;Update ADOPTERS.md' }));

    await vm.vm.$nextTick();

    expect(vm.find('.commit-row-description').html()).toBe(
      '<pre class="commit-row-description gl-mb-3">Update ADOPTERS.md</pre>',
    );
  });

  it('renders the signature HTML as returned by the backend', async () => {
    factory(createCommitData({ signatureHtml: '<button>Verified</button>' }));

    await vm.vm.$nextTick();

    expect(vm.element).toMatchSnapshot();
  });

  it('sets correct CSS class if the commit message is empty', async () => {
    factory(createCommitData({ message: '' }));

    await vm.vm.$nextTick();

    expect(vm.find('.item-title').classes()).toContain(emptyMessageClass);
  });
});
