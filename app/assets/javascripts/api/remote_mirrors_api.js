import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const REMOTE_MIRROR_PATH = '/api/:version/projects/:id/remote_mirrors/:mirror_id';
const REMOTE_MIRROR_SYNC_PATH = '/api/:version/projects/:id/remote_mirrors/:mirror_id/sync';

const buildMirrorUrl = (path, projectId, mirrorId) =>
  buildApiUrl(path)
    .replace(':id', encodeURIComponent(projectId))
    .replace(':mirror_id', encodeURIComponent(mirrorId));

export const deleteRemoteMirror = (projectId, mirrorId) =>
  axios.delete(buildMirrorUrl(REMOTE_MIRROR_PATH, projectId, mirrorId));

export const syncRemoteMirror = (projectId, mirrorId) =>
  axios.post(buildMirrorUrl(REMOTE_MIRROR_SYNC_PATH, projectId, mirrorId));

export const updateRemoteMirror = (projectId, mirrorId, data) =>
  axios.put(buildMirrorUrl(REMOTE_MIRROR_PATH, projectId, mirrorId), data);
