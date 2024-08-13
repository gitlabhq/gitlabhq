import path from 'node:path';
import { readdir } from 'node:fs/promises';

const GITLAB_SVG_PATH = '@gitlab/svgs/dist';

export async function IconsPlugin() {
  return {
    name: 'vite-plugin-gitlab-icons',
    async config() {
      const iconsPath = path.resolve(__dirname, '../..', 'node_modules', GITLAB_SVG_PATH);
      const files = await readdir(iconsPath, { withFileTypes: true });
      const alias = files
        .filter(file => file.isDirectory() || path.extname(file.name) === '.svg')
        .map((file) => {
          return {
            find: file.name,
            replacement: `${iconsPath}/${file.name}`,
          }
        });
      return {
        resolve: {
          alias,
        }
      }
    }
  };
}
