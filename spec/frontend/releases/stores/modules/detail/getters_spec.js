import * as getters from '~/releases/stores/modules/edit_new/getters';
import { i18n } from '~/releases/constants';
import { validateTag, ValidationResult } from '~/lib/utils/ref_validator';

jest.mock('~/lib/utils/ref_validator', () => {
  const original = jest.requireActual('~/lib/utils/ref_validator');
  return {
    __esModule: true,
    ValidationResult: original.ValidationResult,
    validateTag: jest.fn(() => new original.ValidationResult()),
  };
});

describe('Release edit/new getters', () => {
  describe('releaseLinksToCreate', () => {
    it("returns an empty array if state.release doesn't exist", () => {
      const state = {};
      expect(getters.releaseLinksToCreate(state)).toEqual([]);
    });

    it("returns all release links that aren't empty", () => {
      const emptyLinks = [
        { url: '', name: '' },
        { url: ' ', name: '' },
        { url: ' ', name: ' ' },
        { url: '\r\n', name: '\t' },
      ];

      const nonEmptyLinks = [
        { url: 'https://example.com/1', name: 'Example 1' },
        { url: '', name: 'Example 2' },
        { url: 'https://example.com/3', name: '' },
      ];

      const state = {
        release: {
          assets: {
            links: [...emptyLinks, ...nonEmptyLinks],
          },
        },
      };

      expect(getters.releaseLinksToCreate(state)).toEqual(nonEmptyLinks);
    });
  });

  describe('releaseLinksToDelete', () => {
    it("returns an empty array if state.originalRelease doesn't exist", () => {
      const state = {};
      expect(getters.releaseLinksToDelete(state)).toEqual([]);
    });

    it('returns all links associated with the original release', () => {
      const originalLinks = [
        { url: 'https://example.com/1', name: 'Example 1' },
        { url: 'https://example.com/2', name: 'Example 2' },
      ];

      const state = {
        originalRelease: {
          assets: {
            links: originalLinks,
          },
        },
      };

      expect(getters.releaseLinksToDelete(state)).toEqual(originalLinks);
    });
  });

  describe('validationErrors', () => {
    const validState = {
      release: {
        tagName: 'test-tag-name',
        assets: {
          links: [
            { id: 1, url: 'https://example.com/valid', name: 'Link 1' },
            { id: 2, url: '', name: '' },
            { id: 3, url: '', name: ' ' },
            { id: 4, url: ' ', name: '' },
            { id: 5, url: ' ', name: ' ' },
          ],
        },
      },
    };
    describe('when the form is valid', () => {
      const state = validState;
      it('returns no validation errors', () => {
        const expectedErrors = {
          assets: {
            links: {
              1: {},
              2: {},
              3: {},
              4: {},
              5: {},
            },
          },
        };

        expect(getters.validationErrors(state).assets).toEqual(expectedErrors.assets);
        expect(getters.validationErrors(state).tagNameValidation.isValid).toBe(true);
      });
    });

    describe('when validating tag', () => {
      const state = validState;
      it('validateTag is called with right parameters', () => {
        getters.validationErrors(state);
        expect(validateTag).toHaveBeenCalledWith(state.release.tagName);
      });

      it('validation error is correctly returned', () => {
        const validationError = new ValidationResult();
        const errorText = 'Tag format validation error';
        validationError.addValidationError(errorText);
        validateTag.mockReturnValue(validationError);

        const result = getters.validationErrors(state);
        expect(validateTag).toHaveBeenCalledWith(state.release.tagName);
        expect(result.tagNameValidation.validationErrors).toContain(errorText);
      });
    });

    describe('when the form is invalid', () => {
      let actualErrors;

      beforeEach(() => {
        const state = {
          release: {
            // empty tag name
            tagName: '',

            assets: {
              links: [
                // Duplicate URLs
                { id: 1, url: 'https://example.com/duplicate', name: 'Link 1' },
                { id: 2, url: 'https://example.com/duplicate', name: 'Link 2' },

                // the validation check ignores leading/trailing
                // whitespace and is case-insensitive
                { id: 3, url: '  \tHTTPS://EXAMPLE.COM/DUPLICATE\n\r\n  ', name: 'Link 3' },

                // Invalid URL format
                { id: 4, url: 'invalid', name: 'Link 4' },

                // Missing URL
                { id: 5, url: '', name: 'Link 5' },
                { id: 6, url: ' ', name: 'Link 6' },

                // Missing title
                { id: 7, url: 'https://example.com/valid/1', name: '' },
                { id: 8, url: 'https://example.com/valid/2', name: '  ' },

                // Duplicate title
                { id: 9, url: 'https://example.com/1', name: 'Link 7' },
                { id: 10, url: 'https://example.com/2', name: 'Link 7' },

                // title validation ignores leading/trailing whitespace
                { id: 11, url: 'https://example.com/3', name: '  Link 7\t  ' },
                { id: 12, url: 'https://example.com/4', name: ' Link 7\n\r\n ' },
              ],
            },
          },
          // tag has an existing release
          existingRelease: {},
        };

        actualErrors = getters.validationErrors(state);
      });

      it('returns a validation error if the tag name is empty', () => {
        expect(actualErrors.tagNameValidation.isValid).toBe(false);
        expect(actualErrors.tagNameValidation.validationErrors).toContain(
          i18n.tagNameIsRequiredMessage,
        );
      });

      it('returns a validation error if the tag has an existing release', () => {
        expect(actualErrors.tagNameValidation.isValid).toBe(false);
        expect(actualErrors.tagNameValidation.validationErrors).toContain(
          i18n.tagIsAlredyInUseMessage,
        );
      });

      it('returns a validation error if links share a URL', () => {
        const expectedErrors = {
          assets: {
            links: {
              1: { isDuplicate: true },
              2: { isDuplicate: true },
              3: { isDuplicate: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the URL is in the wrong format', () => {
        const expectedErrors = {
          assets: {
            links: {
              4: { isBadFormat: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the URL missing (and the title is populated)', () => {
        const expectedErrors = {
          assets: {
            links: {
              6: { isUrlEmpty: true },
              5: { isUrlEmpty: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the title missing (and the URL is populated)', () => {
        const expectedErrors = {
          assets: {
            links: {
              7: { isNameEmpty: true },
              8: { isNameEmpty: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if links share a title', () => {
        const expectedErrors = {
          assets: {
            links: {
              9: { isTitleDuplicate: true },
              10: { isTitleDuplicate: true },
              11: { isTitleDuplicate: true },
              12: { isTitleDuplicate: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });
    });
  });

  describe('isValid', () => {
    // the value of state is not actually used by this getter
    const state = {};

    describe('when the form is valid', () => {
      it('returns true', () => {
        const mockGetters = {
          validationErrors: {
            assets: {
              links: {
                1: {},
              },
            },
          },
        };

        expect(getters.isValid(state, mockGetters)).toBe(true);
      });
    });

    describe('when an asset link contains a validation error', () => {
      it('returns false', () => {
        const mockGetters = {
          validationErrors: {
            assets: {
              links: {
                1: { isNameEmpty: true },
              },
            },
          },
        };

        expect(getters.isValid(state, mockGetters)).toBe(false);
      });
    });

    describe('when the tag name is empty', () => {
      it('returns false', () => {
        const mockGetters = {
          validationErrors: {
            isTagNameEmpty: true,
            assets: {
              links: {
                1: {},
              },
            },
          },
        };

        expect(getters.isValid(state, mockGetters)).toBe(false);
      });
    });
  });

  describe.each([
    [
      'returns all the data needed for the releaseUpdate GraphQL query',
      {
        projectPath: 'projectPath',
        release: {
          tagName: 'release.tagName',
          name: 'release.name',
          description: 'release.description',
          milestones: ['release.milestone[0].title'],
          releasedAt: new Date(2022, 5, 30),
        },
      },
      {
        projectPath: 'projectPath',
        tagName: 'release.tagName',
        name: 'release.name',
        description: 'release.description',
        milestones: ['release.milestone[0].title'],
        releasedAt: new Date(2022, 5, 30),
      },
    ],
    [
      'trims whitespace from the release name',
      { release: { name: '  name  \t\n' } },
      { name: 'name' },
    ],
    [
      'returns the name as null if the name is nothing but whitespace',
      { release: { name: '  \t\n' } },
      { name: null },
    ],
    ['returns the name as null if the name is undefined', { release: {} }, { name: null }],
    [
      'returns just the milestone titles even if the release includes full milestone objects',
      { release: { milestones: [{ title: 'release.milestone[0].title' }] } },
      { milestones: ['release.milestone[0].title'] },
    ],
  ])('releaseUpdateMutatationVariables', (description, state, expectedVariables) => {
    it(`${description}`, () => {
      const expectedVariablesObject = { input: expect.objectContaining(expectedVariables) };

      const actualVariables = getters.releaseUpdateMutatationVariables(state, {
        releasedAtChanged: Object.hasOwn(state.release, 'releasedAt'),
      });

      expect(actualVariables).toEqual(expectedVariablesObject);
    });
  });

  describe('releaseCreateMutatationVariables', () => {
    it('returns all the data needed for the releaseCreate GraphQL query', () => {
      const state = {
        createFrom: 'main',
        release: { tagMessage: 'hello' },
      };

      const otherGetters = {
        releaseUpdateMutatationVariables: {
          input: {
            name: 'release.name',
          },
        },
        releaseLinksToCreate: [
          {
            name: 'link.name',
            url: 'link.url',
            linkType: 'link.linkType',
          },
        ],
      };

      const expectedVariables = {
        input: {
          name: 'release.name',
          tagMessage: 'hello',
          ref: 'main',
          assets: {
            links: [
              {
                name: 'link.name',
                url: 'link.url',
                linkType: 'LINK.LINKTYPE',
              },
            ],
          },
        },
      };

      const actualVariables = getters.releaseCreateMutatationVariables(state, otherGetters);

      expect(actualVariables).toEqual(expectedVariables);
    });
  });

  describe('releaseDeleteMutationVariables', () => {
    it('returns all the data needed for the releaseDelete GraphQL mutation', () => {
      const state = {
        projectPath: 'test-org/test',
        release: { tagName: 'v1.0' },
      };

      const expectedVariables = {
        input: {
          projectPath: 'test-org/test',
          tagName: 'v1.0',
        },
      };

      const actualVariables = getters.releaseDeleteMutationVariables(state);

      expect(actualVariables).toEqual(expectedVariables);
    });
  });

  describe('formattedReleaseNotes', () => {
    it.each`
      description        | includeTagNotes | tagNotes       | included | isNewTag
      ${'release notes'} | ${true}         | ${'tag notes'} | ${true}  | ${false}
      ${'release notes'} | ${true}         | ${''}          | ${false} | ${false}
      ${'release notes'} | ${false}        | ${'tag notes'} | ${false} | ${false}
      ${'release notes'} | ${true}         | ${'tag notes'} | ${true}  | ${true}
      ${'release notes'} | ${true}         | ${''}          | ${false} | ${true}
      ${'release notes'} | ${false}        | ${'tag notes'} | ${false} | ${true}
    `(
      'should include tag notes=$included when includeTagNotes=$includeTagNotes and tagNotes=$tagNotes and isNewTag=$isNewTag',
      ({ description, includeTagNotes, tagNotes, included, isNewTag }) => {
        let state;

        if (isNewTag) {
          state = {
            release: { description, tagMessage: tagNotes },
            includeTagNotes,
          };
        } else {
          state = { release: { description }, includeTagNotes, tagNotes };
        }

        const text = `### ${'Tag message'}\n\n${tagNotes}\n`;
        if (included) {
          expect(getters.formattedReleaseNotes(state, { isNewTag })).toContain(text);
        } else {
          expect(getters.formattedReleaseNotes(state, { isNewTag })).not.toContain(text);
        }
      },
    );
  });

  describe('releasedAtChange', () => {
    it('is false if the released at date has not changed', () => {
      const date = new Date();
      expect(
        getters.releasedAtChanged({ originalReleasedAt: date, release: { releasedAt: date } }),
      ).toBe(false);
    });

    it('is true if the date changed', () => {
      const originalReleasedAt = new Date();
      const releasedAt = new Date(2022, 5, 30);
      expect(getters.releasedAtChanged({ originalReleasedAt, release: { releasedAt } })).toBe(true);
    });
  });

  describe('localStorageKey', () => {
    it('returns a string key with the project path for local storage', () => {
      const projectPath = 'test/project';
      expect(getters.localStorageKey({ projectPath })).toBe('test/project/release/new');
    });
  });

  describe('localStorageCreateFromKey', () => {
    it('returns a string key with the project path for local storage', () => {
      const projectPath = 'test/project';
      expect(getters.localStorageCreateFromKey({ projectPath })).toBe(
        'test/project/release/new/createFrom',
      );
    });
  });
});
