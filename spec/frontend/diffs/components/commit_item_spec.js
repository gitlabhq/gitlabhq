import { mount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';
import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import Component from '~/diffs/components/commit_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status.vue';

const TEST_AUTHOR_NAME = 'test';
const TEST_AUTHOR_EMAIL = 'test+test@gitlab.com';
const TEST_AUTHOR_GRAVATAR = `${TEST_HOST}/avatar/test?s=40`;
const TEST_SIGNATURE_HTML = `<a class="btn signature-badge" data-content="signature-content" data-html="true" data-placement="top" data-title="signature-title" data-toggle="popover" role="button" tabindex="0">
  <span class="gl-badge badge badge-pill badge-success md">Verified</span>
</a>`;
const TEST_PIPELINE_STATUS_PATH = `${TEST_HOST}/pipeline/status`;

describe('diffs/components/commit_item', () => {
  let wrapper;

  const timeago = getTimeago();
  const { commit } = getDiffWithCommit;

  const findTitleElement = () => wrapper.find('.commit-row-message.item-title');
  const findDescElement = () => wrapper.find('pre.commit-row-description');
  const findDescExpandElement = () => wrapper.find('.commit-content .js-toggle-button');
  const findShaElement = () => wrapper.find('[data-testid="commit-sha-group"]');
  const findUserAvatar = () => wrapper.findComponent(UserAvatarLink);
  const findCommitterElement = () => wrapper.find('.committer');
  const findCommitActionsElement = () => wrapper.find('.commit-actions');
  const findCommitPipelineStatus = () => wrapper.findComponent(CommitPipelineStatus);
  const findCommitCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const mountComponent = (propsData) => {
    wrapper = mount(Component, {
      propsData: {
        commit,
        ...propsData,
      },
      stubs: {
        CommitPipelineStatus: true,
      },
    });
  };

  describe('default state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders commit title', () => {
      const titleElement = findTitleElement();

      expect(titleElement.attributes('href')).toBe(commit.commit_url);
      expect(titleElement.text()).toBe(commit.title_html);
    });

    it('renders commit description', () => {
      const descElement = findDescElement();
      const descExpandElement = findDescExpandElement();

      const expected = commit.description_html.replace(/&#x000A;/g, '');

      expect(trimText(descElement.text())).toEqual(trimText(expected));
      expect(descExpandElement.exists()).toBe(true);
    });

    it('renders commit sha', () => {
      const shaElement = findShaElement();
      const labelElement = shaElement.find('[data-testid="commit-sha-short-id"]');
      const buttonElement = shaElement.find('button.input-group-text');

      expect(labelElement.text()).toEqual(commit.short_id);
      expect(buttonElement.props('text')).toBe(commit.id);
    });

    it('renders author avatar', () => {
      expect(findUserAvatar().props()).toMatchObject({
        linkHref: commit.author.web_url,
        imgSrc: commit.author.avatar_url,
        imgAlt: commit.author.name,
        imgSize: 32,
      });
    });

    it('renders committer text', () => {
      const committerElement = findCommitterElement();
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
      const descElement = findDescElement();
      const descExpandElement = findDescExpandElement();

      expect(descElement.exists()).toBe(false);
      expect(descExpandElement.exists()).toBe(false);
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
      expect(findUserAvatar().props()).toMatchObject({
        linkHref: `mailto:${TEST_AUTHOR_EMAIL}`,
        imgSrc: TEST_AUTHOR_GRAVATAR,
        imgAlt: TEST_AUTHOR_NAME,
        imgSize: 32,
      });
    });

    it('renders committer text', () => {
      const committerElement = findCommitterElement();
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
      const actionsElement = findCommitActionsElement();
      const signatureElement = actionsElement.find('.signature-badge');

      expect(signatureElement.html()).toBe(TEST_SIGNATURE_HTML);
    });
  });

  describe('with pipeline status', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit, pipeline_status_path: TEST_PIPELINE_STATUS_PATH },
      });
    });

    it('renders pipeline status', () => {
      expect(findCommitPipelineStatus().exists()).toBe(true);
    });
  });

  describe('when commit is selectable', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit },
        isSelectable: true,
      });
    });

    it('renders checkbox', () => {
      expect(findCommitCheckbox().exists()).toBe(true);
    });

    it('emits "handleCheckboxChange" event on change', () => {
      expect(wrapper.emitted('handleCheckboxChange')).toBeUndefined();
      findCommitCheckbox().vm.$emit('change');

      expect(wrapper.emitted('handleCheckboxChange')[0]).toEqual([true]);
    });
  });
});
