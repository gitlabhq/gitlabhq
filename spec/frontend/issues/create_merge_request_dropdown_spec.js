import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import confidentialState from '~/confidential_merge_request/state';
import CreateMergeRequestDropdown from '~/issues/create_merge_request_dropdown';
import axios from '~/lib/utils/axios_utils';

const REFS_PATH = `${TEST_HOST}/dummy/refs?search=`;

describe('CreateMergeRequestDropdown', () => {
  let axiosMock;
  let dropdown;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    document.body.innerHTML = `
      <div id="dummy-wrapper-element" data-refs-path="${REFS_PATH}">
        <div class="available"></div>
        <div class="unavailable">
          <div class="js-create-mr-spinner"></div>
          <div class="text"></div>
        </div>
        <div class="js-ref"></div>
        <div class="js-create-mr"></div>
        <div class="js-create-merge-request">
          <span class="js-spinner"></span>
        </div>
        <div class="js-create-target"></div>
        <div class="js-dropdown-toggle"></div>
      </div>
    `;

    const dummyElement = document.getElementById('dummy-wrapper-element');
    dropdown = new CreateMergeRequestDropdown(dummyElement);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('getRef', () => {
    it('escapes branch names correctly', async () => {
      const endpoint = `${REFS_PATH}contains%23hash`;
      jest.spyOn(axios, 'get');
      axiosMock.onGet(endpoint).replyOnce({});

      await dropdown.getRef('contains#hash');
      expect(axios.get).toHaveBeenCalledWith(
        endpoint,
        expect.objectContaining({ cancelToken: expect.anything() }),
      );
    });
  });

  describe('enable', () => {
    beforeEach(() => {
      dropdown.createMergeRequestButton.classList.add('disabled');
    });

    afterEach(() => {
      confidentialState.selectedProject = {};
    });

    it('enables button when not confidential issue', () => {
      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).not.toContain('disabled');
    });

    it('enables when can create confidential issue', () => {
      document.querySelector('.js-create-mr').dataset.isConfidential = 'true';
      confidentialState.selectedProject = { name: 'test' };

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).not.toContain('disabled');
    });

    it('does not enable when can not create confidential issue', () => {
      document.querySelector('.js-create-mr').dataset.isConfidential = 'true';

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).toContain('disabled');
    });
  });

  describe('setLoading', () => {
    it.each`
      loading  | hasClass
      ${true}  | ${false}
      ${false} | ${true}
    `('toggle loading spinner when loading is $loading', ({ loading, hasClass }) => {
      dropdown.setLoading(loading);

      expect(document.querySelector('.js-spinner').classList.contains('gl-display-none')).toEqual(
        hasClass,
      );
    });
  });
});
