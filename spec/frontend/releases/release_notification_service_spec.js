import {
  popCreateReleaseNotification,
  putCreateReleaseNotification,
  popDeleteReleaseNotification,
  putDeleteReleaseNotification,
} from '~/releases/release_notification_service';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

jest.mock('~/alert');

describe('~/releases/release_notification_service', () => {
  const projectPath = 'test-project-path';
  const releaseName = 'test-release-name';

  describe('create release', () => {
    const storageKey = `createRelease:${projectPath}`;

    describe('prepareFlash', () => {
      it('should set the session storage with project path key and release name value', () => {
        putCreateReleaseNotification(projectPath, releaseName);

        const item = window.sessionStorage.getItem(storageKey);

        expect(item).toBe(releaseName);
      });
    });

    describe('showNotificationsIfPresent', () => {
      describe('if notification is prepared', () => {
        beforeEach(() => {
          window.sessionStorage.setItem(storageKey, releaseName);
          popCreateReleaseNotification(projectPath);
        });

        it('should remove storage key', () => {
          const item = window.sessionStorage.getItem(storageKey);

          expect(item).toBe(null);
        });

        it('should create an alert message', () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: `Release ${releaseName} has been successfully created.`,
            variant: VARIANT_SUCCESS,
          });
        });
      });

      describe('if notification is not prepared', () => {
        beforeEach(() => {
          popCreateReleaseNotification(projectPath);
        });

        it('should not create an alert message', () => {
          expect(createAlert).toHaveBeenCalledTimes(0);
        });
      });
    });
  });

  describe('delete release', () => {
    const storageKey = `deleteRelease:${projectPath}`;

    describe('prepareFlash', () => {
      it('should set the session storage with project path key and release name value', () => {
        putDeleteReleaseNotification(projectPath, releaseName);

        const item = window.sessionStorage.getItem(storageKey);

        expect(item).toBe(releaseName);
      });
    });

    describe('showNotificationsIfPresent', () => {
      describe('if notification is prepared', () => {
        beforeEach(() => {
          window.sessionStorage.setItem(storageKey, releaseName);
          popDeleteReleaseNotification(projectPath);
        });

        it('should remove storage key', () => {
          const item = window.sessionStorage.getItem(storageKey);

          expect(item).toBe(null);
        });

        it('should create an alert message', () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: `Release ${releaseName} has been successfully deleted.`,
            variant: VARIANT_SUCCESS,
          });
        });
      });

      describe('if notification is not prepared', () => {
        beforeEach(() => {
          popDeleteReleaseNotification(projectPath);
        });

        it('should not create an alert message', () => {
          expect(createAlert).toHaveBeenCalledTimes(0);
        });
      });
    });
  });
});
