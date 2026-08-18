import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('ProtectedTagCreate', () => {
  let mock;

  useMockLocationHelper();

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = {
      create_access_levels: { roles: [] },
      open_tags: [],
    };
  });

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  const create = ({ withUpdateSection = true } = {}) => {
    const updateSectionInput = withUpdateSection
      ? '<input type="hidden" name="update_section" value="js-protected-tags-settings" />'
      : '';

    setHTMLFixture(`
      <form class="js-new-protected-tag" method="post" action="/protected_tags">
        <input type="hidden" name="authenticity_token" value="token" />
        ${updateSectionInput}
        <input type="text" name="protected_tag[name]" value="v1.*" />
        <div class="js-allowed-to-create"></div>
        <button type="submit">Protect</button>
      </form>
    `);

    return new ProtectedTagCreate({ hasLicense: false });
  };

  const submitForm = async () => {
    document
      .querySelector('form.js-new-protected-tag')
      .dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    await waitForPromises();
  };

  describe('form submission', () => {
    describe('when the tag is protected successfully', () => {
      beforeEach(() => {
        mock.onPost('/protected_tags').reply(HTTP_STATUS_OK);
      });

      it('anchors the settings section named by the form and reloads, so it renders expanded', async () => {
        create();

        await submitForm();

        expect(window.location.hash).toBe('js-protected-tags-settings');
        expect(window.location.reload).toHaveBeenCalled();
      });

      it('still reloads when the form names no section to return to', async () => {
        create({ withUpdateSection: false });

        await submitForm();

        expect(window.location.hash).toBeUndefined();
        expect(window.location.reload).toHaveBeenCalled();
      });
    });

    describe('when protecting the tag fails', () => {
      it('shows an alert and does not reload', async () => {
        mock.onPost('/protected_tags').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        create();

        await submitForm();

        expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to protect the tag' });
        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });
  });
});
