export function isTemplate() {
  return window.location.href.includes('/wikis/templates');
}

function deslugify(slug) {
  return slug.replace(/-+/g, ' ');
}

export function sidebarEntriesToTree(entries) {
  if (!entries.length) return [];

  const regex = new RegExp(`${entries[0].slug.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')}$`);
  const rootPath = entries[0].path.replace(regex, '');
  const entriesMap = entries.reduce((acc, entry) => {
    acc[entry.slug] = entry;
    return acc;
  }, {});

  return entries
    .sort(({ slug: slugA }, { slug: slugB }) => {
      return slugA.localeCompare(slugB, undefined, {
        numeric: true,
        sensitivity: 'base',
      });
    })
    .reduce((acc, entry) => {
      const parts = entry.slug.split('/');
      let parent = acc;

      for (let i = 0; i < parts.length; i += 1) {
        const part = parts[i];
        const subSlug = parts.slice(0, i + 1).join('/');
        const existing = parent.find((child) => child.slug === subSlug);

        if (existing) {
          parent = existing.children;
        } else {
          const subEntry = entriesMap[subSlug];
          const node = {
            slug: subSlug,
            path: subEntry?.path || `${rootPath}${subSlug}`,
            title: subEntry?.title || deslugify(part),
            children: [],
          };

          parent.push(node);
          parent = node.children;
        }
      }

      return acc;
    }, []);
}
