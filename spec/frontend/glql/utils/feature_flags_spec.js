import { glqlWorkItemsFeatureFlagEnabled } from '~/glql/utils/feature_flags';

describe('glqlWorkItemsFeatureFlagEnabled', () => {
  let originalWindowLocation;
  let originalGon;

  beforeEach(() => {
    // Save original window.location and gon
    originalWindowLocation = window.location;
    originalGon = window.gon;

    // Mock window.location
    delete window.location;
    window.location = new URL('https://gitlab.example.com');

    // Mock gon
    window.gon = { features: {} };
  });

  afterEach(() => {
    // Restore original values
    window.location = originalWindowLocation;
    window.gon = originalGon;
  });

  it('returns false when URL parameter glqlWorkItems=false is present, regardless of gon setting', () => {
    window.location.search = '?glqlWorkItems=false';
    window.gon.features.glqlWorkItems = true;

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(false);
  });

  it('returns true when gon.features.glqlWorkItems is true and no URL parameter is present', () => {
    window.location.search = '';
    window.gon.features.glqlWorkItems = true;

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(true);
  });

  it('returns true when gon.features.glqlWorkItems is true and URL parameter is not "false"', () => {
    window.location.search = '?glqlWorkItems=true';
    window.gon.features.glqlWorkItems = true;

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(true);
  });

  it('returns false when gon.features.glqlWorkItems is false, regardless of URL parameter', () => {
    window.location.search = '?glqlWorkItems=true';
    window.gon.features.glqlWorkItems = false;

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(false);
  });

  it('returns false when gon.features.glqlWorkItems is undefined, regardless of URL parameter', () => {
    window.location.search = '?glqlWorkItems=true';

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(false);
  });

  it('handles case when gon.features is undefined', () => {
    window.location.search = '';
    window.gon = {};

    expect(glqlWorkItemsFeatureFlagEnabled()).toBe(false);
  });
});
