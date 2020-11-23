import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import { getTimeago } from '~/lib/utils/datetime_utility';
import Component from '~/diffs/components/commit_item.vue';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import getDiffWithCommit from '../mock_data/diff_with_commit';

jest.mock('~/user_popovers');

const TEST_AUTHOR_NAME = 'test';
const TEST_AUTHOR_EMAIL = 'test+test@gitlab.com';
const TEST_AUTHOR_GRAVATAR = `${TEST_HOST}/avatar/test?s=40`;
const TEST_SIGNATURE_HTML = '<a>Legit commit</a>';
const TEST_PIPELINE_STATUS_PATH = `${TEST_HOST}/pipeline/status`;
const NEXT_COMMIT_URL = `${TEST_HOST}/?commit_id=next`;
const PREV_COMMIT_URL = `${TEST_HOST}/?commit_id=prev`;

describe('diffs/components/commit_item', () => {
  let wrapper;

  const timeago = getTimeago();
  const { commit } = getDiffWithCommit();

  const getTitleElement = () => wrapper.find('.commit-row-message.item-title');
  const getDescElement = () => wrapper.find('pre.commit-row-description');
  const getDescExpandElement = () => wrapper.find('.commit-content .js-toggle-button');
  const getShaElement = () => wrapper.find('[data-testid="commit-sha-group"]');
  const getAvatarElement = () => wrapper.find('.user-avatar-link');
  const getCommitterElement = () => wrapper.find('.committer');
  const getCommitActionsElement = () => wrapper.find('.commit-actions');
  const getCommitPipelineStatus = () => wrapper.find(CommitPipelineStatus);

  const getCommitNavButtonsElement = () => wrapper.find('.commit-nav-buttons');
  const getNextCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:last-child');
  const getPrevCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:first-child');

  const mountComponent = (propsData, featureFlags = {}) => {
    wrapper = mount(Component, {
      propsData: {
        commit,
        ...propsData,
      },
      provide: {
        glFeatures: {
          mrCommitNeighborNav: true,
          ...featureFlags,
        },
      },
      stubs: {
        CommitPipelineStatus: true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders commit title', () => {
      const titleElement = getTitleElement();

      expect(titleElement.attributes('href')).toBe(commit.commit_url);
      expect(titleElement.text()).toBe(commit.title_html);
    });

    it('renders commit description', () => {
      const descElement = getDescElement();
      const descExpandElement = getDescExpandElement();

      const expected = commit.description_html.replace(/&#x000A;/g, '');

      expect(trimText(descElement.text())).toEqual(trimText(expected));
      expect(descExpandElement.exists()).toBe(true);
    });

    it('renders commit sha', () => {
      const shaElement = getShaElement();
      const labelElement = shaElement.find('[data-testid="commit-sha-short-id"]');
      const buttonElement = shaElement.find('button.input-group-text');

      expect(labelElement.text()).toEqual(commit.short_id);
      expect(buttonElement.props('text')).toBe(commit.id);
    });

    it('renders author avatar', () => {
      const avatarElement = getAvatarElement();
      const imgElement = avatarElement.find('img');

      expect(avatarElement.attributes('href')).toBe(commit.author.web_url);
      expect(imgElement.classes()).toContain('s40');
      expect(imgElement.attributes('alt')).toBe(commit.author.name);
      expect(imgElement.attributes('src')).toBe(commit.author.avatar_url);
    });

    it('renders committer text', () => {
      const committerElement = getCommitterElement();
      const nameElement = committerElement.find('a');

      const expectTimeText = timeago.format(commit.authored_date);
      const expectedText = `${commit.author.name} authored ${expectTimeText}`;

      expect(trimText(committerElement.text())).toEqual(expectedText);
      expect(nameElement.attributes('href')).toBe(commit.author.web_url);
      expect(nameElement.text()).toBe(commit.author.name);
      expect(nameElement.classes()).toContain('js-user-link');
      expect(nameElement.attributes('data-user-id')).toEqual(commit.author.id.toString());
    });
  });

  describe('without commit description', () => {
    beforeEach(() => {
      mountComponent({ commit: { ...commit, description_html: '' } });
    });

    it('hides description', () => {
      const descElement = getDescElement();
      const descExpandElement = getDescExpandElement();

      expect(descElement.exists()).toBeFalsy();
      expect(descExpandElement.exists()).toBeFalsy();
    });
  });

  describe('with no matching user', () => {
    beforeEach(() => {
      mountComponent({
        commit: {
          ...commit,
          author: null,
          author_email: TEST_AUTHOR_EMAIL,
          author_name: TEST_AUTHOR_NAME,
          author_gravatar_url: TEST_AUTHOR_GRAVATAR,
        },
      });
    });

    it('renders author avatar', () => {
      const avatarElement = getAvatarElement();
      const imgElement = avatarElement.find('img');

      expect(avatarElement.attributes('href')).toBe(`mailto:${TEST_AUTHOR_EMAIL}`);
      expect(imgElement.attributes('alt')).toBe(TEST_AUTHOR_NAME);
      expect(imgElement.attributes('src')).toBe(TEST_AUTHOR_GRAVATAR);
    });

    it('renders committer text', () => {
      const committerElement = getCommitterElement();
      const nameElement = committerElement.find('a');

      expect(nameElement.attributes('href')).toBe(`mailto:${TEST_AUTHOR_EMAIL}`);
      expect(nameElement.text()).toBe(TEST_AUTHOR_NAME);
    });
  });

  describe('with signature', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit, signature_html: TEST_SIGNATURE_HTML },
      });
    });

    it('renders signature html', () => {
      const actionsElement = getCommitActionsElement();

      expect(actionsElement.html()).toContain(TEST_SIGNATURE_HTML);
    });
  });

  describe('with pipeline status', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit, pipeline_status_path: TEST_PIPELINE_STATUS_PATH },
      });
    });

    it('renders pipeline status', () => {
      expect(getCommitPipelineStatus().exists()).toBe(true);
    });
  });

  describe('without neighbor commits', () => {
    beforeEach(() => {
      mountComponent({ commit: { ...commit, prev_commit_id: null, next_commit_id: null } });
    });

    it('does not render any navigation buttons', () => {
      expect(getCommitNavButtonsElement().exists()).toEqual(false);
    });
  });

  describe('with neighbor commits', () => {
    let mrCommit;

    beforeEach(() => {
      mrCommit = {
        ...commit,
        next_commit_id: 'next',
        prev_commit_id: 'prev',
      };

      mountComponent({ commit: mrCommit });
    });

    it('renders the commit navigation buttons', () => {
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      mountComponent({
        commit: { ...mrCommit, next_commit_id: null },
      });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      mountComponent({
        commit: { ...mrCommit, prev_commit_id: null },
      });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);
    });

    it('does not render the commit navigation buttons if the `mrCommitNeighborNav` feature flag is disabled', () => {
      mountComponent({ commit: mrCommit }, { mrCommitNeighborNav: false });

      expect(getCommitNavButtonsElement().exists()).toEqual(false);
    });

    describe('prev commit', () => {
      const { location } = window;

      beforeAll(() => {
        delete window.location;
        window.location = { href: `${TEST_HOST}?commit_id=${mrCommit.id}` };
      });

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      });

      afterAll(() => {
        window.location = location;
      });

      it('uses the correct href', () => {
        const link = getPrevCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(PREV_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', () => {
        const link = getPrevCommitNavElement();

        link.trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.moveToNeighboringCommit).toHaveBeenCalledWith({
            direction: 'previous',
          });
        });
      });

      it('renders a disabled button when there is no prev commit', () => {
        mountComponent({ commit: { ...mrCommit, prev_commit_id: null } });

        const button = getPrevCommitNavElement();

        expect(button.element.tagName).toEqual('BUTTON');
        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });

    describe('next commit', () => {
      const { location } = window;

      beforeAll(() => {
        delete window.location;
        window.location = { href: `${TEST_HOST}?commit_id=${mrCommit.id}` };
      });

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      });

      afterAll(() => {
        window.location = location;
      });

      it('uses the correct href', () => {
        const link = getNextCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(NEXT_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', () => {
        const link = getNextCommitNavElement();

        link.trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.moveToNeighboringCommit).toHaveBeenCalledWith({ direction: 'next' });
        });
      });

      it('renders a disabled button when there is no next commit', () => {
        mountComponent({ commit: { ...mrCommit, next_commit_id: null } });

        const button = getNextCommitNavElement();

        expect(button.element.tagName).toEqual('BUTTON');
        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });
  });
});
