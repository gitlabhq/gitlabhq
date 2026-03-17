# Code Style Guidelines

## Frontend (Vue/JavaScript)

### Pajamas Design System

When using GitLab UI components, follow Pajamas guidelines strictly:

- **Component selection**: Each Pajamas component has "when to use" and "when not to use" guidance. Review these before selecting a component.
  - Reference: https://design.gitlab.com/components/
  - Reference: https://docs.gitlab.com/development/contributing/design/
- **Component overrides**: If you need multiple CSS overrides to change a component's default appearance (borders, backgrounds, padding), this indicates the component may not be the right fit. Consider utility classes or a different component instead.
- **Utility classes vs components**: For simple visual styling needs (borders, rounded corners, padding) without structured content, prefer Tailwind utility classes over container components.
  - Reference: https://docs.gitlab.com/development/fe_guide/style/scss/#utility-classes
- **Design tokens**: Use design tokens, not hardcoded values. Avoid fixed type scales outside of Markdown contexts.
  - Reference: https://docs.gitlab.com/development/fe_guide/design_tokens/
  - Reference: https://design.gitlab.com/product-foundations/design-tokens/

### Reference Documentation

- Pajamas Design System: https://design.gitlab.com/
- Frontend development guide: https://docs.gitlab.com/development/fe_guide/
- SCSS/Utility classes: https://docs.gitlab.com/development/fe_guide/style/scss/
- Design and UI changes checklist: https://docs.gitlab.com/development/contributing/design/
