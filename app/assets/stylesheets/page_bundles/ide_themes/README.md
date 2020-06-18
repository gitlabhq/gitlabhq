# Web IDE Themes

Web IDE currently supports 5 syntax highlighting themes based on themes from the user's profile preferences:

* White
* Dark
* Monokai
* Solarized Dark
* Solarized Light

Currently, the Web IDE supports the white theme by default, and the dark theme by the introduction of CSS
variables.

The Web IDE automatically adds an appropriate theme class to the `ide.vue` component based on the current syntax
highlighting theme. Below are those theme classes, which come from the `gon.user_color_scheme` global setting:

| # | Color Scheme    | `gon.user_color_scheme` | Theme class             |
|---|-----------------|-------------------------|-------------------------|
| 1 | White           | `"white"`               | `.theme-white`           |
| 2 | Dark            | `"dark"`                | `.theme-dark`            |
| 3 | Monokai         | `"monokai"`             | `.theme-monokai`         |
| 4 | Solarized Dark  | `"solarized-dark"`      | `.theme-solarized-dark`  |
| 5 | Solarized Light | `"solarized-light"`     | `.theme-solarized-light` |
| 6 | None            | `"none"`                | `.theme-none`            |

## Adding New Themes (SCSS)

To add a new theme, follow the following steps:

1. Pick a theme from the table above, lets say **Solarized Dark**.
2. Create a new file in this folder called `_solarized_dark.scss`.
3. Copy over all the CSS variables from `_dark.scss` to `_solarized_dark.scss` and assign them your own values.
   Put them under the selector `.ide.theme-solarized-dark`.
4. Import this newly created SCSS file in `ide.scss` file in the parent directory.
5. That's it! Raise a merge request with your newly added theme.

## Modifying Monaco Themes

Monaco themes are defined in Javascript and are stored in the `app/assets/javascripts/ide/lib/themes/` directory.
To modify any syntax highlighting colors or to synchronize the theme colors with syntax highlighting colors, you
can modify the files in that directory directly.
