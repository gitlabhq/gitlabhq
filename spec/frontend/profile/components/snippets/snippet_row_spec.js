import { GlAvatar, GlSprintf, GlIcon } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import { SNIPPET_VISIBILITY } from '~/snippets/constants';
import SnippetRow from '~/profile/components/snippets/snippet_row.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_USER, MOCK_SNIPPET } from 'jest/profile/mock_data';

describe('UserProfileSnippetRow', () => {
  let wrapper;

  const defaultProps = {
    userInfo: MOCK_USER,
    snippet: MOCK_SNIPPET,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SnippetRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlAvatar = () => wrapper.findComponent(GlAvatar);
  const findSnippetUrl = () => wrapper.findByTestId('snippet-url');
  const findSnippetId = () => wrapper.findByTestId('snippet-id');
  const findSnippetCreatedAt = () => wrapper.findByTestId('snippet-created-at');
  const findSnippetAuthor = () => wrapper.findByTestId('snippet-author');
  const findSnippetBlob = () => wrapper.findByTestId('snippet-blob');
  const findSnippetComments = () => wrapper.findByTestId('snippet-comments');
  const findSnippetVisibility = () => wrapper.findByTestId('snippet-visibility');
  const findSnippetUpdatedAt = () => wrapper.findByTestId('snippet-updated-at');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlAvatar with user avatar', () => {
      expect(findGlAvatar().exists()).toBe(true);
      expect(findGlAvatar().attributes('src')).toBe(MOCK_USER.avatarUrl);
    });

    it('renders Snippet Url with snippet webUrl', () => {
      expect(findSnippetUrl().exists()).toBe(true);
      expect(findSnippetUrl().attributes('href')).toBe(MOCK_SNIPPET.webUrl);
    });

    it('renders Snippet ID correctly formatted', () => {
      expect(findSnippetId().exists()).toBe(true);
      expect(findSnippetId().text()).toBe(`$${getIdFromGraphQLId(MOCK_SNIPPET.id)}`);
    });

    it('renders Snippet Created At with correct date string', () => {
      expect(findSnippetCreatedAt().exists()).toBe(true);
      expect(findSnippetCreatedAt().attributes('time')).toBe(MOCK_SNIPPET.createdAt.toString());
    });

    it('renders Snippet Author with profileLink', () => {
      expect(findSnippetAuthor().exists()).toBe(true);
      expect(findSnippetAuthor().attributes('href')).toBe(`/${MOCK_USER.username}`);
    });

    it('renders Snippet Updated At with correct date string', () => {
      expect(findSnippetUpdatedAt().exists()).toBe(true);
      expect(findSnippetUpdatedAt().attributes('time')).toBe(MOCK_SNIPPET.updatedAt.toString());
    });
  });

  describe.each`
    nodes                                            | hasOpacity | tooltip
    ${[]}                                            | ${true}    | ${'0 files'}
    ${[{ name: 'file.txt' }]}                        | ${false}   | ${'1 file'}
    ${[{ name: 'file.txt' }, { name: 'file2.txt' }]} | ${false}   | ${'2 files'}
  `('Blob Icon', ({ nodes, hasOpacity, tooltip }) => {
    describe(`when blobs length ${nodes.length}`, () => {
      beforeEach(() => {
        createComponent({ snippet: { ...MOCK_SNIPPET, blobs: { nodes } } });
      });

      it(`does${hasOpacity ? '' : ' not'} render icon with opacity`, () => {
        expect(findSnippetBlob().findComponent(GlIcon).props('name')).toBe('documents');
        expect(findSnippetBlob().classes('gl-opacity-5')).toBe(hasOpacity);
      });

      it('renders text and tooltip correctly', () => {
        expect(findSnippetBlob().text()).toBe(nodes.length.toString());
        expect(findSnippetBlob().attributes('title')).toBe(tooltip);
      });
    });
  });

  describe.each`
    nodes                                   | hasOpacity
    ${[]}                                   | ${true}
    ${[{ id: 'note/1' }]}                   | ${false}
    ${[{ id: 'note/1' }, { id: 'note/2' }]} | ${false}
  `('Comments Icon', ({ nodes, hasOpacity }) => {
    describe(`when comments length ${nodes.length}`, () => {
      beforeEach(() => {
        createComponent({ snippet: { ...MOCK_SNIPPET, notes: { nodes } } });
      });

      it(`does${hasOpacity ? '' : ' not'} render icon with opacity`, () => {
        expect(findSnippetComments().findComponent(GlIcon).props('name')).toBe('comments');
        expect(findSnippetComments().classes('gl-opacity-5')).toBe(hasOpacity);
      });

      it('renders text correctly', () => {
        expect(findSnippetComments().text()).toBe(nodes.length.toString());
      });

      it('renders link to comments correctly', () => {
        expect(findSnippetComments().attributes('href')).toBe(`${MOCK_SNIPPET.webUrl}#notes`);
      });
    });
  });

  describe.each`
    visibilityLevel
    ${VISIBILITY_LEVEL_PUBLIC_STRING}
    ${VISIBILITY_LEVEL_PRIVATE_STRING}
    ${VISIBILITY_LEVEL_INTERNAL_STRING}
  `('Visibility Icon', ({ visibilityLevel }) => {
    describe(`when visibilityLevel is ${visibilityLevel}`, () => {
      beforeEach(() => {
        createComponent({ snippet: { ...MOCK_SNIPPET, visibilityLevel } });
      });

      it(`renders the ${SNIPPET_VISIBILITY[visibilityLevel].icon} icon`, () => {
        expect(findSnippetVisibility().findComponent(GlIcon).props('name')).toBe(
          SNIPPET_VISIBILITY[visibilityLevel].icon,
        );
      });
    });
  });
});
